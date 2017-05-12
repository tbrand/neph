module Neph
  module Parser
    def parse_yaml(job_name : String, path : String) : Job
      abort error("config file doesn't exist at #{path}") unless File.exists?(path)
      abort error("#{path} is not a file") unless File.file?(path)

      config = YAML.parse(File.read(path)).as_h

      job = create_job(config, job_name)
      job
    end

    def create_job(config : YAML::Type, job_name : String, parent_job : Job? = nil) : Job
      unless config.is_a?(YHash)
        abort error("Invalid structure in '#{job_name}'")
      end

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
      job.chdir = job_config["chdir"].as(String) if job_config.has_key?("chdir")
      job.ignore_error = if job_config["ignore_error"].as(String) == "true"
                           true
                         else
                           false
                         end if job_config.has_key?("ignore_error")

      if job_config.has_key?("sources")
        if job_config["sources"].is_a?(YArray)
          job_config["sources"].as(YArray).each do |source|
            job.add_sources(source_files(source.as(String)))
          end
        else
          job.add_sources(source_files(job_config["sources"].as(String)))
        end
      end
      
      if job_config.has_key?("depends_on")
        if job_config["depends_on"].is_a?(YArray)
          job_config["depends_on"].as(YArray).each do |sub_job_name|
            add_sub_job(config, job, sub_job_name.as(String))
          end
        elsif job_config["depends_on"].is_a?(String)
          add_sub_job(config, job, job_config["depends_on"].as(String))
        end
      end

      job
    end

    def add_sub_job(config, job : Job, sub_job_name : String)
      if sub_job_name == job.name
        abort "Cannot specify same name jobs to 'depends_on' <- on '#{sub_job_name}' job"
      end

      if job.has_parent_job?(sub_job_name)
        abort "There are loop jobs between '#{sub_job_name}' and '#{job.name}'"
      end

      job.add_sub_job(create_job(config, sub_job_name.as(String), job))
    end

    def source_files(path : String) : Array(String)
      relative_path = File.expand_path(path, Dir.current)
      Dir.glob(relative_path)
    end
  end
end
