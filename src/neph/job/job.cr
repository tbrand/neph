module Neph
  class Job
    TICK_CHARS = "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ "

    WAITING = 0
    RUNNING = 1
    DONE    = 2
    ERROR   = 3
    SKIP    = 4

    getter name         : String
    getter command      : String
    getter ws_dir       : String
    getter log_dir      : String
    getter tmp_dir      : String
    getter depends_on   : Array(Job)
    getter status_code  : Int32 = 0
    getter elapsed_time : String

    property chdir : String = Dir.current
    property ignore_error : Bool = false
    property sources : Array(String) = [] of String

    def initialize(@name : String, @command : String)
      @depends_on = [] of Job
      @ws_dir = "#{neph_dir}/#{@name}"
      @log_dir = "#{@ws_dir}/log"
      @tmp_dir = "#{@ws_dir}/tmp"
      @step = 0
      @status = WAITING
      @elapsed_time = ""
    end

    def add_sub_job(job : Job)
      @depends_on.push(job)
    end

    def add_sources(source_files : Array(String))
      source_files.each do |file|
        @sources.push(file)
      end
    end

    def create_dir
      Dir.mkdir(@ws_dir) unless Dir.exists?(@ws_dir)
      Dir.mkdir(@log_dir) unless Dir.exists?(@log_dir)
      Dir.mkdir(@tmp_dir) unless Dir.exists?(@tmp_dir)
    end

    def get_progress : String
      progress = TICK_CHARS[@step%TICK_CHARS.size].to_s
      @step += 1
      progress
    end

    def status_msg
      case @status
      when WAITING
        return "waiting #{get_progress}".colorize.fore(:light_yellow).to_s + " #{progress_msg}"
      when RUNNING
        return "running #{get_progress}".colorize.fore(:light_cyan).to_s + " #{progress_msg}"
      when DONE
        return "done.".colorize.fore(:light_gray).to_s + " #{progress_msg} #{@elapsed_time}"
      when ERROR
        return "error!".colorize.fore(:red).to_s + " #{progress_msg}"
      when SKIP
        return "up to date".colorize.fore(:light_blue).to_s + " #{progress_msg}"
      end
    end

    def to_s(indent = 0) : String
      indent_spaces = "" + " " * (indent * 4)

      job_s = String::Builder.new("#{@name}".colorize.mode(:bold).to_s + " #{status_msg}\n")

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
      "[#{progress}/#{progress_max}] #{progress_percent}%"
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
      @status == DONE || @status == ERROR || @status == SKIP
    end

    def exec(channel : Channel(Job))
      @status = WAITING
      exec_sub_job if @depends_on.size > 0

      create_dir

      @status = RUNNING

      if up_to_date?
        @status = SKIP
      else
        exec_self

        if @status_code == 0
          @status = DONE
        else
          clean_tmp
          @status = ERROR
        end
      end

      channel.send(self)
    end

    def clean_tmp
      @sources.each do |source|
        File.delete(tmp_file(source)) if File.exists?(tmp_file(source))
      end
    end

    def up_to_date? : Bool
      return false if @sources.size == 0

      res = true
      @sources.each do |source|
        stat = File.stat(source)
        
        if File.exists?(tmp_file(source))
          tmp_stat = File.stat(tmp_file(source))
          if stat.ctime != tmp_stat.atime
            File.touch(tmp_file(source), stat.ctime)
            res = false
          end
        else
          File.touch(tmp_file(source), stat.ctime)
          res = false
        end
      end

      res
    end

    def tmp_file(source : String) : String
      "#{@tmp_dir}/#{source.gsub("/", "_")}"
    end

    def exec_self
      stdout = File.open("#{@log_dir}/#{log_out}", "w")
      stderr = File.open("#{@log_dir}/#{log_err}", "w")

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
          if !sub_job.ignore_error
            log_ln error("'#{sub_job.name}' failed with status code (#{sub_job.status_code})"), true
            log_ln error("Error log exists at #{sub_job.log_dir}/#{log_err}"), true
            exit -1
          end
        end
      end
    end

    include Neph
  end
end
