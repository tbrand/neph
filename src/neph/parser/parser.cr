module Neph
  module Parser
    def parse_yaml(path : String) : YAML::Type
      abort error("yaml doesn't exist at #{path}") unless File.exists?(path)
      abort error("#{path} is not a file") unless File.file?(path)

      config = YAML.parse(File.read(path)).as_h

      unless config.is_a?(YHash)
        abort error("Invalid structure in '#{path}'")
      end

      config
    end

    def parse_yaml(job_name : String, path : String) : Job
      config = parse_yaml(path)

      if config.has_key?("import")
        if config["import"].is_a?(YArray)
          config["import"].as(YArray).each do |import|
            config.merge!(parse_yaml(import.as(String)))
          end
        elsif config["import"].is_a?(String)
          config.merge!(parse_yaml(config["import"].as(String)))
        end
      end

      job = create_job(config, job_name)
      job
    end

    def create_job(config : YAML::Type, job_name : String, parent_job : Job? = nil) : Job
      unless config.has_key?(job_name)
        abort error("'#{job_name}' is not found")
      end

      job_config = config[job_name].as(YHash)
      job_command = if job_config.has_key?("command")
                      job_config["command"].as(String)
                    else
                      ""
                    end

      job = Job.new(job_name, job_command, parent_job)
      job.dir = job_config["dir"].as(String) if job_config.has_key?("dir")
      job.ignore_error = job_config["ignore_error"] ? true : false if job_config.has_key?("ignore_error")
      job.hide = job_config["hide"] ? true : false if job_config.has_key?("hide")

      if job_config.has_key?("src")
        if job_config["src"].is_a?(YArray)
          job_config["src"].as(YArray).each do |source|
            job.add_sources(source_files(source.as(String)))
          end
        else
          job.add_sources(source_files(job_config["src"].as(String)))
        end
      end

      if job_config.has_key?("depends_on")
        if job_config["depends_on"].is_a?(YArray)
          job_config["depends_on"].as(YArray).each do |sub_job|
            abort "Invalid structure in #{job_name}'s dependencies" if sub_job.is_a?(YArray | Nil)
            add_sub_job(config, job, sub_job.as(String | YHash))
          end
        else
          sub_job = job_config["depends_on"]
          abort "Invalid structure in #{job_name}'s dependencies" if sub_job.is_a?(YArray | Nil)
          add_sub_job(config, job, sub_job.as(String | YHash))
        end
      end

      job
    end

    def add_sub_job(config : YHash, job : Job, sub_job : String)
      add_sub_job(config, job, sub_job, nil)
    end

    def add_sub_job(config : YHash, job : Job, sub_job : YHash)
      unless sub_job.has_key?("job")
        abort "Please specify 'job' for the #{job.name}'s dependency"
      end

      if sub_job.has_key?("env")
        add_sub_job(config, job, sub_job["job"].as(String), sub_job["env"].as(String))
      else
        add_sub_job(config, job, sub_job["job"].as(String), nil)
      end
    end

    def add_sub_job(config : YHash, job : Job, sub_job_name : String, env : String?)
      if sub_job_name == job.name
        abort "Cannot specify same name jobs to 'depends_on' <- on '#{sub_job_name}' job"
      end

      if job.has_parent_job?(sub_job_name)
        abort "There are loop jobs between '#{sub_job_name}' and '#{job.name}'"
      end

      job.add_sub_job(create_job(config, sub_job_name, job), env)
    end

    def source_files(path : String) : Array(String)
      relative_path = File.expand_path(path, Dir.current)
      Dir.glob(relative_path)
    end
  end
end
