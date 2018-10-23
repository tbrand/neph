module Neph
  module Parser
    def parse_yaml(path : String) : Hash(YAML::Any, YAML::Any)
      abort error("yaml doesn't exist at #{path}") unless File.exists?(path)
      abort error("#{path} is not a file") unless File.file?(path)

      unless config = YAML.parse(File.read(path)).as_h?
        abort error("Invalid structure in '#{path}'")
      end

      config
    end

    def parse_yaml(job_name : String, path : String) : Job
      config = parse_yaml(path)

      if config.has_key?("import")
        if imports = config["import"].as_a?
          imports.each do |import|
            config.merge!(parse_yaml(import.as_s))
          end
        elsif import = config["import"].as_s?
          config.merge!(parse_yaml(config["import"].as_s))
        end
      end

      job = create_job(config, job_name)
      job
    end

    def create_job(config : Hash(YAML::Any, YAML::Any), job_name : String, parent_job : Job? = nil) : Job
      unless config.has_key?(job_name)
        abort error("'#{job_name}' is not found")
      end

      job_config = config[job_name].as_h
      job_commands = if job_config.has_key?("commands")
                      job_config["commands"].as_a.map { |c| c.as_s }
                    else
                      [] of String
                     end
      job_before = if job_config.has_key?("before")
                     job_config["before"].as_a.map { |c| c.as_s }
                   else
                     [] of String
                   end
      job_after = if job_config.has_key?("after")
                     job_config["after"].as_a.map { |c| c.as_s }
                   else
                     [] of String
                   end

      job = Job.new(job_name, job_commands, job_before, job_after, parent_job)
      job.dir = job_config["dir"].as_s if job_config.has_key?("dir")
      job.ignore_error = job_config["ignore_error"] ? true : false if job_config.has_key?("ignore_error")
      job.hide = job_config["hide"] ? true : false if job_config.has_key?("hide")

      if job_config.has_key?("src")
        if srcs = job_config["src"].as_a?
          srcs.each do |source|
            job.add_sources(source_files(source.as_s))
          end
        else
          job.add_sources(source_files(job_config["src"].as_s))
        end
      end

      if job_config.has_key?("depends_on")
        if dependencies = job_config["depends_on"].as_a?
          job_config["depends_on"].as_a.each do |sub_job|
            if sub_job_h = sub_job.as_h?
              add_sub_job(config, job, sub_job_h)
            elsif sub_job_s = sub_job.as_s?
              add_sub_job(config, job, sub_job_s)
            else
              abort "Invalid structure in #{job_config["depends_on"]}'s dependencies"
            end
          end
        elsif depedency = job_config["depends_on"].as_s?
          add_sub_job(config, job, depedency)
        else
          abort "Invalid structure in #{job_config["depends_on"]}'s dependencies"
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
        add_sub_job(config, job, sub_job["job"].as_s, sub_job["env"].as_s)
      else
        add_sub_job(config, job, sub_job["job"].as_s, nil)
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
