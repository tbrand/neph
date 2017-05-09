module Neph
  class Job
    TICK_CHARS = "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ "
    WAITING = 0
    RUNNING = 1
    DONE    = 2
    ERROR   = 3
    SKIP    = 4

    getter name            : String
    getter command         : String
    getter ws_dir          : String
    getter log_dir         : String
    getter tmp_dir         : String
    getter depends_on      : Array(Job)
    getter status_code     : Int32 = 0
    getter elapsed_time    : String
    getter current_command : String = ""
    getter done_command    : Int32 = 0
    getter commands        : Array(String) = [] of String

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

      @commands = @command.split("\n").reject do |command|
        command.empty?
      end unless @command.empty?
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

    def status_msg(indent_spaces = "")
      case @status
      when WAITING
        return progress_msg + " #{get_progress} waiting".colorize.fore(:light_yellow).to_s
      when RUNNING
        return progress_msg + " #{get_progress} running (#{progress_percent}%)".colorize.fore(:light_cyan).to_s + " > #{@current_command}".colorize.mode(:bright).to_s
      when DONE
        return progress_msg + " done.".colorize.fore(:light_gray).to_s + "   #{@elapsed_time}"
      when ERROR
        return progress_msg + " error!".colorize.fore(:red).to_s
      when SKIP
        return progress_msg + " up to date".colorize.fore(:light_blue).to_s
      end
    end

    def to_s(indent = 0) : String
      indent_spaces = "" + " " * (indent * 4)
      job_s = String::Builder.new("#{@name}".colorize.mode(:bold).to_s + " #{status_msg(indent_spaces)}")
      job_s << "\n"

      depends_on.each do |sub_job|
        job_s << "#{indent_spaces} - #{sub_job.to_s(indent + 1)}"
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
      "[#{progress}/#{progress_max}]"
    end

    def progress_percent : Int32
      return 100 if @commands.size == 0
      ((@done_command.to_f/@commands.size.to_f) * 100.0).to_i
    end

    def progress : Int32
      num_of_done_jobs
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
          if (stat.ctime - tmp_stat.atime).to_i != 0
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

      unless @commands.size == 0

        @commands.each do |command|

          next if command.empty?

          @current_command = command
          process = Process.run(
            @current_command,
            shell: true,
            output: stdout,
            error: stderr,
            chdir: @chdir
          )

          @done_command += 1
          unless process.exit_status == 0
            @status_code = process.exit_status
            break
          end
        end
      end

      e = Time.now
      @elapsed_time = format_time(e-s)
      stdout.close
      stderr.close
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
