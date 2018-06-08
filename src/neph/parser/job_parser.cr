class Neph::Parser::JobParser
  @raw_job_list : Hash(String, YAML::Type)
  @config : Config
  @job_list : Hash(String, Job) = {} of String => Job

  def initialize(@raw_job_list : Hash(String, YAML::Type), @config : Config)
  end

  def parse_jobs
    # Check if @config.main_job exists in job list.
    unless @raw_job_list.has_key? @config.main_job
      raise "The job list doesn't contain the '#{@config.main_job}' job (specified with the 'main_job' config option)."
    end

    # The dependency stack is empty.
    parse_job_recursively [] of String, @config.main_job
  end

  private def parse_job_recursively(dependency_stack : Array(String), job_name : String) : Job
    # Check if job_name is valid.
    unless @raw_job_list.has_key? job_name
      # The last item of 'dependency_stack' is the parent job.
      raise JobError.new dependency_stack.last, "The following sub-job isn't defined: '#{job_name}'"
    end

    # Check if job is already parsed, and return the parsed job if it is.
    return @job_list[job_name] if @job_list.has_key? job_name

    # Check for circular dependencies.
    if dependency_stack.includes? job_name
      # Find the position of the current job name in the dependency stack,
      # and remove job names before it, because these job names aren't
      # involved in the dependency circle.
      dependency_circle = dependency_stack.skip_while { |i| i != job_name }

      # Add current job name to the end of the dependency circle.
      dependency_circle << job_name

      raise "Circular job dependencies found: " + dependency_circle.join " → "
    end

    # Type check.
    raise JobError.new job_name, "Job definition have to be a mapping." unless @raw_job_list[job_name].is_a? Hash

    job_definition = @raw_job_list[job_name].as Hash

    # Type check of keys
    unless job_definition.keys.all? &.is_a? String
      raise JobError.new job_name, "All keys have to be String in job definition."
    end

    job = Job.new job_name

    # Apply configuration to Job.
    job.interpreter = @config.interpreter

    job_definition.each do |key, value|
      case key
      when "commands"
        # Type check.
        unless value.is_a? Array && (value = value.as Array).all?(&.is_a? String)
          raise JobError.new job_name, "Command list have to be a sequence of strings."
        end

        # Add it to the job.
        job.commands = value.map &.as(String)
      when "dependencies"
        # Type check.
        unless value.is_a? Array && (value = value.as Array).all?(&.is_a? String)
          raise JobError.new job_name, "Dependency list have to be a sequence of strings."
        end

        # Parse subjobs recursively
        dependencies = [] of Job
        value.each do |dependency_name|
          dependencies << parse_job_recursively (dependency_stack << job_name), dependency_name.as String
        end

        # Add it to the job
        job.sub_jobs = dependencies
      when "repeat"
        unless value.is_a? Bool
          raise JobError.new job_name, "The value of the 'repeat' parameter have to be a boolean value."
        end

        job.repeat = value.as Bool
      else
        # The valid parameters for a job.
        valid_parameters = {"dependencies", "commands"}

        raise "Wrong keyword ('#{key}') in the definition of the '#{job_name}' job. " + Parser.construct_keyword_suggestion key.as String, valid_parameters
      end
    end
    @job_list[job_name] = job
    return job
  end
end
