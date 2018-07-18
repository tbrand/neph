class Neph::Parser
  @filename : String
  property main_job_override : String?

  def initialize(path : String, @main_job_override = nil)
    raise "No such file: #{path}" unless File.exists? path
    raise "Unable to open '#{path}'" unless File.readable? path

    # Change directory to the dirname of the alternative_file path.
    # This is needed because the `include` config option uses paths
    # relative to the build file, and also all commands are launched
    # from the directory the build file is in.
    Dir.cd File.dirname path

    @filename = File.basename path
  end

  # Parse the YAML config
  # Returns the main job.
  def parse : Job
    # Parse the content of the file into Crystal data
    parsed_main : Array(YAML::Any) = YAML.parse_all(File.read @filename)

    # If the parsed document contains two parts, then
    # we have a config too, if it has only one part, then
    # it only contains the jobs.
    case parsed_main.size
    when 1
      # Create the job list with the default config.
      config = Config.new
      config.main_job = @main_job_override.as(String) if @main_job_override
      return parse_jobs parsed_main[0], config
    when 2
      # First document is the config, second contains the job list.
      return parse_jobs parsed_main[1], parse_config(parsed_main[0])
    else
      # If the config contains more than 2 documents, or 0, raise an exception.
      raise "Invalid neph.yaml file. It contains too much (#{parsed_main.size}) YAML documents.\n\
        The neph.yaml file can only contain 1 or 2 YAML documents."
    end
  end

  # Parse the job list from YAML.
  # Returns the main job.
  private def parse_jobs(raw_main : YAML::Any, config : Config = Config.new) : Job
    # The job list have to be a Hash.
    # Keys are the job names, and the values are the job definitions.
    raise Error.new "The job list have to be a mapping." unless raw_main.as_h?

    # Job names have to be strings.
    raise Error.new "Job names have to be strings." unless raw_main.as_h.keys.all? &.as_s?

    # This will contain all YAML document with job definitions.
    documents : Array(YAML::Any) = [raw_main]

    # Read each included file.
    Dir.glob(config.include).each do |filename|
      documents << parse_included_file filename
    end

    # Every item in 'documents' contains a Hash(YAML::Any, YAML::Any), the types of the keys
    # are checked (every underlying value is a String), so restrict type of keys to it: Hash(String, YAML::Any)
    # Every document in 'documents' will be merged to this Hash.
    job_list = {} of String => YAML::Any

    # Merge all document from `documents`, and check for duplicated job names.
    documents.each do |doc|
      # Iterate over each key-value pair in job list.
      # Keys and values are `YAML::Any`, but keys contains strings.
      doc.as_h.each do |job_name, definition|
        # Check for duplicated job names.
        if job_list.has_key? job_name.as_s
          # There is a duplicated job name.
          raise "Duplicated job name: #{job_name}"
        else
          # Add job name and job definition to the merged Hash.
          job_list[job_name.as_s] = definition
        end
      end
    end

    job_parser = JobParser.new(job_list, config)
    job_parser.parse_jobs
  end

  private def parse_included_file(filename : String)
    # Read and parse content of 'filename'.
    parsed_doc : YAML::Any = YAML.parse File.read filename

    # The job list have to be a Hash.
    # Keys are the job names, and the values are the job definitions.
    raise "Error in #{filename}: The job list have to be a mapping." unless parsed_doc.as_h?

    # Job names have to be strings, job definitions have to be mappings.
    # `parsed_doc` is a `Hash(YAML::Any, YAML::Any)`
    parsed_doc.as_h.each do |job_name, definition|
      unless job_name.as_s?
        raise "Error in #{filename}: Job names have to be strings. #{job_name.raw} is a #{job_name.raw.class}"
      end
    end
    parsed_doc
  end

  # Parse the configuration part of the main file.
  # The config part is a YAML document, that comes first in the config file, before the job listing.
  # It may raise if the configuration has invalid syntax, or types.
  # Higher level errors are not checked in this method (e.g. the job name specified by 'main_job' isn't in the job list).
  # an example config file:
  # ```yaml
  # # This is the config part.
  # interpreter: elvish
  # main_job: build
  # ---
  # # Here comes the job list.
  # ```
  private def parse_config(raw : YAML::Any) : Config
    config = Config.new

    # If the document is valid, `config` will be a Hash(YAML::Any, YAML::Any), raise otherwise.
    unless raw_config = raw.as_h?
      raise "Invalid configuration part (first YAML document). It have to be a mapping, instead of #{raw.raw.class}"
    end

    # `raw_config` : Hash(YAML::Any, YAML::Any)
    raw_config.each do |key, value|
      # Check type of `key`.
      key = key.as_s?
      unless key
        raise ConfigError.new "Every key have to be a string. '#{key}' is a '#{key.class}'"
      end

      # Search for a valid Neph config key.
      case key
      # This have to be a list of paths.
      # Shell style globs are allowed, these will be expanded later.
      when "include"
        # It have to be an Array.
        unless value.as_a?
          raise ConfigError.new "The list of included files have to be a sequence."
        end

        value = value.as_a

        # Every element of the array have to be String
        if value.all? &.as_s?
          # Add it to the configuration.
          config.include = value.map &.as_s
        else
          # Find the elements that has incorrect types (other than String).
          incorrect_types = value.reject { |i| i.as_s? }

          # This string will be appended to the error message.
          # It will explain to the user what elements has
          # wrong type, and what is that type.
          wrong_type_message = "The following elements have wrong types:\n"
          incorrect_types.each do |i|
            # Append a line to the error message, which contains the element with wrong type and its Crystal class.
            wrong_type_message += "'#{i}' is a #{i.class}\n"
          end
          raise ConfigError.new "The list of included files have to be a sequence of String.\n" + wrong_type_message.chomp
        end
      when "interpreter"
        # If it is an array, then every element of the it have to be String.
        if value.as_a? && value.as_a.all?(&.as_s?)
          # Type inference don't work here (value.all? &.as_s?), so it requires a manual workaround.
          config.interpreter = Job::Interpreter.new *parse_interpreter_arguments(value.as_a.map &.as_s)
        elsif value = value.as_s? # If it is a String, then it have to be one of the builtins.
          # There is no builtin with this name.
          unless Job::Interpreter::BUILTINS.has_key? value
            raise ConfigError.new "If the `interpreter` config key has a String value, \
              it have to be one of the following: #{Job::Interpreter::BUILTINS.keys.join(", ")}. \n\
              Otherwise it have to be a mapping."
          else
            config.interpreter = Job::Interpreter::BUILTINS[value]
          end
        else
          raise ConfigError.new "The list of interpreter arguments have to be a sequence of strings."
        end
      when "main_job"
        # It have to be a String
        if value = value.as_s?
          # Add it to the configuration.
          config.main_job = value
        else
          raise ConfigError.new "The name of the 'main_job' have to be a String, not a #{value.class}."
        end
      when "environment"
        # It have to be a mapping.
        unless value.as_h?
          raise ConfigError.new "The value of the environment variable definitions (the 'environment' key) have to be a mapping."
        end

        # It have to map String to String
        if (value = value.as_h).keys.all?(&.as_s?) && value.values.all?(&.as_s?)
          # `value` is a `Hash(YAML::Any, YAML::Any)`
          value.each { |k, v| ENV[k.as_s] = v.as_s }
        else
          raise ConfigError.new "The value of the environment variable definitions (the 'environment' key) have to be a mapping of string to string."
        end
      else                                                # There is an invalid Neph configuration keyword.
        keywords = {"include", "interpreter", "main_job"} # The valid configuration keywords:

        raise ConfigError.new "Invalid keyword: '#{key}'. " + Parser.construct_keyword_suggestion(key, keywords)
      end
    end
    config.main_job = @main_job_override.as(String) if @main_job_override
    config
  end

  # Parse the argument list for the interpreter if it is specified as an array.
  # It will return an `Array` of `String|Symbol`.
  # When the interpreter is launched, every Symbol in this array should be replaced by the command.
  #
  # It uses simple rules to decide if a string should be parsed to Symbol (so it will be replaced by the command).
  # - If a string **starts with** a character **other than `/`**, then it will be used as an argument **without modification**.
  # - If the string is **equal to `/command`**, then it will be **substituted by the command** when the interpreter is launched (so **it will be a `Symbol`**).
  # - If the string starts with `/`, but isn't equal to `/command`, then a **single** `/` character will be **removed** from the **beginning of the string**.
  #   **Any other `/` characters in the string won't be modified.**
  #
  # It will raise if the first argument is a `Symbol` (it have to be a `String`, because it is the name of the interpreter executable).
  private def parse_interpreter_arguments(argument_list : Array(String)) : {String, Array(String | Symbol)}
    parsed_arguments = argument_list.map do |i|
      if i == "/command"
        # If it is equal to `/command`, then return a Symbol.
        :command
      else
        # Return it as a String, with the `/` prefix removed (if exists).
        i.lchop '/'
      end
    end

    # The first element of the argument list is the name of the executable,
    # so it can not be a Symbol (it would be replaced with the command).
    if parsed_arguments[0].is_a? Symbol
      raise ConfigError.new "The first element of the argument list of the interpreter is the \
        name of the interpreter executable, so it can't be replaced by the evaluated command."
    end

    # Return a Tuple. The first element is a String, the second is an Array.
    return parsed_arguments.shift.as(String), parsed_arguments
  end

  # It is used when there is an invalid keyword somewhere.
  # It tries to suggest a similar keyword (search using Levenshtein algorithm).
  # If there aren't similar keywords, then list all the valid keywords.
  protected def self.construct_keyword_suggestion(wrong_keyword : String, valid_keywords)
    # If there is a similar valid keyword, suggest it, if there isn't, list all the valid keywords.
    if suggested_keyword = Levenshtein.find wrong_keyword.as(String), valid_keywords
      # There is a similar keyword according to the Levenshtein search.
      suggestion = "Did you mean '#{suggested_keyword}'?"
    else
      suggestion = "Valid keywords are: " + valid_keywords.join ", "
    end

    suggestion
  end
end
