module Neph
  class Job
    WAITING = 0
    RUNNING = 1
    DONE    = 2
    ERROR   = 3

    getter name         : String
    getter command      : String
    getter log_dir      : String
    getter depends_on   : Array(Job)
    getter status_code  : Int32 = 0
    getter elapsed_time : String

    def initialize(@name : String, @command : String, @chdir : String = Dir.current)
      @depends_on = [] of Job
      @log_dir = "#{neph_log_dir}/#{@name}"
      @step = 0
      @status = WAITING
      @elapsed_time = ""
    end

    def add_sub_job(job : Job)
      @depends_on.push(job)
    end

    def create_log_dir
      Dir.mkdir(log_dir) unless Dir.exists?(log_dir)
    end

    def get_progress : String
      progress = if @step%4 == 0
                   "\\"
                 elsif @step%4 == 1
                   "--"
                 elsif @step%4 == 2
                   "/"
                 else
                   "|"
                 end

      @step += 1

      progress
    end

    def status_msg
      case @status
      when WAITING
        return " waiting... ".colorize.fore(:yellow).to_s + " #{progress_msg} #{get_progress}"
      when RUNNING
        return " running... ".colorize.fore(:cyan).to_s + "#{progress_msg} #{get_progress}"
      when DONE
        return " done. ".colorize.fore(:light_blue).to_s + " #{progress_msg} #{@elapsed_time}"
      when ERROR
        return " error! ".colorize.fore(:red).to_s + " #{progress_msg}"
      end
    end

    def to_s(indent = 0) : String
      indent_spaces = "" + " " * (indent * 4)

      job_s = String::Builder.new("#{@name} #{status_msg}\n")

      depends_on.each do |sub_job|
        job_s << "#{indent_spaces} - #{sub_job.to_s(indent+1)}"
      end

      job_s.to_s
    end

    def num_of_jobs
      num = 1
      @depends_on.each do |sub_job|
        num += sub_job.num_of_jobs
      end
      num
    end

    def num_of_done_jobs
      num = if done?
              1
            else
              0
            end

      @depends_on.each do |sub_job|
        num += sub_job.num_of_done_jobs
      end
      num
    end

    def progress_msg : String
      "#{progress}/#{progress_max} (#{progress_percent}%)"
    end

    def progress_percent : Int32
      percent = ((progress.to_f/progress_max.to_f) * 100.0).to_i
    end

    def progress : Int32
      n = num_of_done_jobs

      if n > progress_max
        return progress_max
      else
        return n
      end
    end

    def progress_max : Int32
      num_of_jobs
    end

    def done?
      @status == DONE || @status == ERROR
    end

    def exec(channel : Channel(Job))
      @status = WAITING
      exec_sub_job if @depends_on.size > 0

      create_log_dir

      @status = RUNNING
      exec_self

      if @status_code == 0
        @status = DONE
      else
        @status = ERROR
      end

      channel.send(self)
    end

    def exec_self
      stdout = File.open("#{log_dir}/#{log_out}", "w")
      stderr = File.open("#{log_dir}/#{log_err}", "w")

      s = Time.now

      unless @command.empty?
        process = Process.run(
          @command,
          shell: true,
          output: stdout,
          error: stderr,
          chdir: @chdir
        )
      end

      e = Time.now

      @elapsed_time = format_time(e-s)

      stdout.close
      stderr.close

      @status_code = if process.nil?
                       0
                     else
                       process.exit_status
                     end
    end

    def exec_sub_job
      channel = Channel(Job).new

      depends_on.each do |sub_job|
        spawn do
          sub_job.exec(channel)
        end
      end

      depends_on.each do |_|
        sub_job = channel.receive
        if sub_job.status_code != 0
          puts error("'#{sub_job.name}' failed with status code (#{sub_job.status_code})")
          puts error("Error log exists at #{sub_job.log_dir}/#{log_err}")
          exit -1
        end
      end
    end

    def format_time(time)
      minutes = time.total_minutes
      return "#{minutes.round(2)}m" if minutes >= 1

      seconds = time.total_seconds
      return "#{seconds.round(2)}s" if seconds >= 1

      millis = time.total_milliseconds
      return "#{millis.round(2)}ms" if millis >= 1

      "#{(millis * 1000).round(2)}µs"
    end

    include Neph
  end
end
