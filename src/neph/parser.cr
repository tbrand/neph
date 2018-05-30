module Neph
  module Parser
    # Parse the YAML config
    def parse_yaml(filename : String)
      # Parse the content of the file into Crystal data
      parsed_main : Array(YAML::Any) = YAML.parse_all(File.read filename)

      # If the parsed document contains two parts, then
      # we have a config too, if it has only one part, then
      # it only contains the jobs.
      case parsed_main.size
      when 1
        # Create the job list from the config.
        parse_jobs parsed_main[0]
      when 2
        # First document is the config, second contains the job list.
        parse_jobs parsed_main[1], parse_config(parsed_main[0])
      else
        # If the config contains more than 2 documents, or 0, raise an exception.
        raise "Invalid neph.yaml file. It contains too much (#{parsed_main.size}) YAML documents.\n\
        The neph.yaml file can only contain 1 or 2 YAML documents."
      end
    end

    # Parse the job list from YAML.
    # Returns the main job.
    def parse_jobs(raw_main : YAML::Any, config : Config = Config.new) : Job
      # The job list have to be a Hash.
      # Keys are the job names, and the values are the job definitions.
      raise Error.new "The job list have to be a mapping." unless raw_main.as_h?

      # Job names have to be strings.
      raise Error.new "Job names have to be strings." unless raw_main.as_h.keys.all? &.is_a? String

      # This will contain all YAML document with job definitions.
      documents : Array(YAML::Any) = [raw_main]

      # Read each included file.
      Dir.glob(config.include).each do |filename|
        documents << parse_included_file filename
      end

      # Every item in 'documents' contains a Hash(YAML::Type, YAML::Type), the types of the keys
      # are checked (every key is a String), so restrict type of keys to it: Hash(String, YAML::Type)
      # Every document in 'documents' will be merged to this Hash.
      job_list = {} of String => YAML::Type

      # Merge all document from `documents`, and check for duplicated job names.
      documents.each do |doc|
        # Iterate over each key-value pair in job list.
        doc.as_h.each do |job_name, definition|
          # Check for duplicated job names.
          if job_list.has_key? job_name.as(String)
            # There is a duplicated job name.
            raise "Duplicated job name: #{job_name}"
          else
            # Add job name and job definition to the merged Hash.
            job_list[job_name.as(String)] = definition
          end
        end
      end

      job_parser = JobParser.new(job_list, config)
      job_parser.parse_jobs
    end

    private def parse_included_file(filename : String)
      # Read and parse content of 'filename'.
      parsed_doc = YAML.parse File.read filename

      # The job list have to be a Hash.
      # Keys are the job names, and the values are the job definitions.
      raise "Error in #{filename}: The job list have to be a mapping." unless parsed_doc.as_h?

      # Job names have to be strings, job definitions have to be mappings.
      parsed_doc.as_h.each do |job_name, definition|
        unless job_name.is_a? String
          raise "Error in #{filename}: Job names have to be strings. #{job_name} is a #{job_name.class}"
        end
      end
      parsed_doc
    end

    # Parse the configuration part of the main file.
    # The config part is a YAML document, that comes first in the config file, before the job listing.
    # It may raise if the configuration has invalid syntax, or types.
    # Higher level errors are not checked in this method (e.g. the job name specified by 'default_job' isn't in the job list).
    # an example config file:
    # ```yaml
    # # This is the config part.
    # interpreter: elvish
    # default_job: build
    # ---
    # # Here comes the job list.
    # ```
    def parse_config(raw : YAML::Any) : Config
      config = Config.new

      # If the document is valid, `config` will be a Hash(YAML::Type, YAML::Type), raise otherwise.
      unless raw_config = raw.as_h?
        raise "Invalid configuration part (first YAML document). It have to be a mapping, instead of #{raw.raw.class}"
      end

      raw_config.each do |key, value|
        # Search for a valid Neph config key.
        case key
        # This have to be a list of paths.
        # Shell style globs are allowed, these will be expanded later.
        when "include"
          # It have to be an Array.
          unless value.is_a?(Array)
            raise ConfigError.new "The list of included files have to be a sequence."
          end

          # Every element of the array have to be String
          if value.all?(&.is_a? String)
            # Add it to the configuration.
            config.include = value.map &.as(String)
          else
            # Find the elements that has incorrect types (other than String).
            incorrect_types = value.reject { |i| i.is_a? String }

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
          if value.is_a?(Array) && value.all?(&.is_a? String)
            # Type inference don't work here (value.all? &.is_a? String), so it requires a manual workaround.
            config.interpreter = Job::Interpreter.new *parse_interpreter_arguments(value.map(&.as String))
          elsif value.is_a?(String) # If it is a String, then it have to be one of the builtins.
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
        when "default_job"
          # It have to be a String
          if value.is_a? String
            # Add it to the configuration.
            config.default_job = value
          else
            raise ConfigError.new "The name of the 'default_job' have to be a String, not a #{value.class}."
          end
        when "env"
          # It have to be a mapping.
          unless value.is_a? Hash
            raise ConfigError.new "The value of the environment variable definitions (the 'env' key) have to be a mapping."
          end

          # It have to map String to String
          if value.keys.all?(&.is_a? String) && value.values.all?(&.is_a? String)
            # Add it to the config.
            value.each { |k, v| config.environment[k.as(String)] = v.as(String) }
          else
            raise ConfigError.new "The value of the environment variable definitions (the 'env' key) have to be a mapping of string to string."
          end
        else
          # It has invalid type.
          unless key.is_a? String
            raise ConfigError.new "Every key have to be a string. '#{key}' is a '#{key.class}'"
          end

          # The type is String, so there is an invalid Neph configuration keyword.

          # The valid Neph configuration keywords.
          keywords = {"include", "interpreter", "default_job", "env"}

          raise ConfigError.new "Invalid keyword: '#{key}'. " + Parser.construct_keyword_suggestion(key, keywords)
        end
      end
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
end
