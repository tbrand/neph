module Neph
  module Parser
    def parse_yaml(job_name : String, path : String) : Job
      abort error("config file doesn't exist at #{path}") unless File.exists?(path)
      
      config = YAML.parse(File.read(path)).as_h

      job = create_job(config, job_name)
      job
    end

    def create_job(config : YAML::Type, job_name : String) : Job
      unless config.is_a?(YHash)
        abort error("Invalid structure in '#{job_name}'")
      end

      unless config.has_key?(job_name)
        abort error("'#{job_name}' is not found")
      end

      job_config = config[job_name].as(YHash)

      if job_config.has_key?("command")
        job = Job.new(job_name, job_config["command"].as(String))
      else
        job = Job.new(job_name, "")
      end

      if job_config.has_key?("depends_on")
        if job_config["depends_on"].is_a?(YArray)
          job_config["depends_on"].as(YArray).each do |sub_job_name|
            job.add_sub_job(create_job(config, sub_job_name.as(String)))
          end
        elsif job_config["depends_on"].is_a?(String)
          job.add_sub_job(create_job(config, job_config["depends_on"].as(String)))
        end
      end

      job
    end
  end
end
