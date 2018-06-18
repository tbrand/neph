class Neph::Parser
  # This is raised when there is an error in the main file (`neph.yaml`)
  class Error < Exception
    def initialize(message : String)
      super "Error in the main file: " + message
    end
  end

  # This is raised, when there is an error in the configuration part of `neph.yaml`.
  class ConfigError < Error
    def initialize(message : String)
      super "The configuration part (first YAML document) is invalid.\n" + message
    end
  end

  # This is raised, when there is an error in a job definition.
  class JobError < Exception
    def initialize(job_name : String, message : String)
      super "There is an error in the definition of the following job: '#{job_name}'\n" + message
    end
  end
end
