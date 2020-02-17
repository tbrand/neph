module Neph
  class Job
    TICK_CHARS = "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ "
    WAITING    = 0
    RUNNING    = 1
    DONE       = 2
    ERROR      = 3
    SKIP       = 4

    getter name : String
    getter ws_dir : String
    getter log_dir : String
    getter tmp_dir : String
    getter depends_on : Array(Job)
    getter status_code : Int32 = 0
    getter elapsed_time : String
    getter current_command : String = ""
    getter done_command : Int32 = 0
    getter commands : Array(String) = [] of String
    getter before : Array(String) = [] of String
    getter after : Array(String) = [] of String

    property env : String?
    property dir : String = Dir.current
    property src : Array(String) = [] of String
    property ignore_error : Bool = false
    property hide : Bool = false

    def initialize(
         @name       : String,
         @commands   : Array(String),
         @before     : Array(String),
         @after      : Array(String),
         @parent_job : Job?
       )
      @depends_on = [] of Job
      @ws_dir = "#{neph_dir}/#{@name}"
      @log_dir = "#{@ws_dir}/log"
      @tmp_dir = "#{@ws_dir}/tmp"
      @step = 0
      @status = WAITING
      @prev_status = -1
      @prev_command = ""
      @elapsed_time = ""
    end

    def add_sub_job(job : Job, env : String?)
      job.env = env if env
      @depends_on.push(job)
    end

    def add_sources(source_files : Array(String))
        @src += source_files
    end

    def create_dir
      Dir.mkdir(@ws_dir) unless Dir.exists?(@ws_dir)
      Dir.mkdir(@log_dir) unless Dir.exists?(@log_dir)
      Dir.mkdir(@tmp_dir) unless Dir.exists?(@tmp_dir)
    end

    def get_progress : String
      progress = TICK_CHARS[@step % TICK_CHARS.size].to_s
      @step += 1
      progress
    end

    def shown_command : String
      return @current_command unless hide
      "HIDDEN"
    end

    def status_msg(indent_spaces = "")
      case @status
      when WAITING
        return "#{@name}".colorize.mode(:bold).to_s + progress_msg + "#{get_progress} waiting".colorize.fore(:light_yellow).to_s
      when RUNNING
        return "#{@name}".colorize.mode(:bold).to_s + progress_msg + "#{get_progress} running (#{progress_percent}%)".colorize.fore(:light_cyan).to_s + " > #{shown_command}".colorize.mode(:bright).to_s
      when DONE
        return "#{@name}".colorize.mode(:bold).to_s + progress_msg + "done.".colorize.fore(:light_gray).to_s + "   #{@elapsed_time}"
      when ERROR
        return "#{@name}".colorize.mode(:bold).to_s + progress_msg + "error!".colorize.fore(:red).to_s
      when SKIP
        return "#{@name}".colorize.mode(:bold).to_s + progress_msg + "up to date".colorize.fore(:light_blue).to_s
      end
    end

    def status_msg_ci
      case @status
      when WAITING
        return "#{time_msg} #{@name}" + " -- waiting".colorize.fore(:light_yellow).to_s
      when RUNNING
        return "#{time_msg} #{@name}" + " -- running".colorize.fore(:light_cyan).to_s + " > #{shown_command}".colorize.mode(:bright).to_s
      when DONE
        return "#{time_msg} #{@name}" + " -- done.".colorize.fore(:light_gray).to_s + " #{@elapsed_time}"
      when ERROR
        return "#{time_msg} #{@name}" + " -- error!".colorize.fore(:red).to_s
      when SKIP
        return "#{time_msg} #{@name}" + " -- up to date".colorize.fore(:light_blue).to_s
      end
    end

    def to_s(indent = 0) : String
      indent_spaces = "" + " " * (indent * 4)
      job_s = String::Builder.new("#{status_msg(indent_spaces)}\n")

      depends_on.each do |sub_job|
        job_s << "#{indent_spaces} - #{sub_job.to_s(indent + 1)}"
      end

      job_s.to_s
    end

    def to_s_ci : String
      job_s = String::Builder.new("")

      depends_on.each do |sub_job|
        sub_job_s = sub_job.to_s_ci
        job_s << "#{sub_job_s}" if sub_job_s.size > 0
      end

      job_s << "#{status_msg_ci}\n" if status_changed?
      job_s.to_s
    end

    def num_of_jobs
      @depends_on.reduce(1) { |sum, sub_job| sum + sub_job.num_of_jobs }
    end

    def num_of_done_jobs
      @depends_on.reduce(done? ? 1 : 0) { |sum, sub_job| sum + sub_job.num_of_done_jobs }
    end

    def progress_msg : String
      " [#{progress}/#{progress_max}] "
    end

    def time_msg : String
      time = Time.local.to_s("%Y-%m-%d %H:%S:%M")
      "[#{time}] "
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

    def done? : Bool
      @status == DONE || @status == ERROR || @status == SKIP
    end

    def status_changed? : Bool
      if @status != @prev_status
        @prev_status = @status
        @prev_command = @current_command
        return true
      end

      if @prev_command != @current_command
        @prev_status = @status
        @prev_command = @current_command
        return true
      end

      false
    end

    def has_parent_job?(sub_job_name : String) : Bool
      return false if @parent_job.nil?
      return true if @parent_job.not_nil!.name == sub_job_name
      return @parent_job.not_nil!.has_parent_job?(sub_job_name)
    end

    def prepare_env
      depends_on.each do |sub_job|
        if env_name = sub_job.env
          ENV[env_name] = File.read("#{sub_job.log_dir}/#{log_out}")
        end
      end
    end

    def exec(channel : Channel(Nil)? = nil)
      @status = WAITING

      if @depends_on.size > 0
        if channel.nil?
          # Sequential execution mode
          exec_sub_job_sequential
        else
          # Parallel execution mode
          exec_sub_job_parallel
        end
      end

      create_dir

      @status = RUNNING

      if up_to_date?
        @status = SKIP
      else
        prepare_env

        exec_self

        if @status_code == 0
          @status = DONE
          @src.each do |i|
            File.touch tmp_file i
          end
        else
          clean_tmp
          @status = ERROR

          unless @ignore_error
            log_ln error("'#{@name}' failed with status code (#{@status_code})"), true
            log_ln error(" -- STDOUT(#{@log_dir}/#{log_out}) -- ")
            log_ln file_tail("#{@log_dir}/#{log_out}")
            log_ln error(" -- STDERR(#{@log_dir}/#{log_err}) -- ")
            log_ln file_tail("#{@log_dir}/#{log_err}")
            exit -1
          end
        end
      end

      channel.not_nil!.send(nil) if channel
    end

    def clean_tmp
      @src.each do |source|
        File.delete(tmp_file(source)) if File.exists?(tmp_file(source))
      end
    end

    #
    # TODO: should be fixed
    #
    def up_to_date? : Bool
      return false unless @src.size > 0

      @src.each do |source|
        stat = File.info(source)

        if File.exists?(tmp_file(source))
          tmp_stat = File.info(tmp_file(source))
          if (stat.modification_time > tmp_stat.modification_time)
            return false
          end
        else
          File.touch(tmp_file(source), stat.modification_time)
          return false
        end
      end
      true
    end

    def tmp_file(source : String) : String
      "#{@tmp_dir}/#{source.gsub("/", "_")}"
    end

    def exec_self
      stdout = File.open("#{@log_dir}/#{log_out}", "w")
      stderr = File.open("#{@log_dir}/#{log_err}", "w")

      s = Time.local

      exec_commands(@before, stdout, stderr)
      exec_commands(@commands, stdout, stderr)
      exec_commands(@after, stdout, stderr)

      @done_command += 1

      e = Time.local
      @elapsed_time = format_time(e - s)
      stdout.close
      stderr.close
    end

    def exec_sub_job_sequential
      depends_on.each do |sub_job|
        sub_job.exec
      end
    end

    def exec_sub_job_parallel
      channel = Channel(Nil).new

      depends_on.each do |sub_job|
        spawn do
          sub_job.exec(channel)
        end
      end

      depends_on.each do |_|
        channel.receive
      end
    end

    def exec_commands(commands : Array(String), stdout, stderr)
      unless commands.size == 0
        commands.each do |command|
          next if command.empty?

          @current_command = command
          process = Process.run(
            @current_command,
            shell: true,
            output: stdout,
            error: stderr,
            chdir: @dir
          )

          @done_command += 1
          unless process.exit_status == 0
            @status_code = process.exit_status
            break
          end
        end
      end      
    end

    def file_tail(path : String) : String
      res = File.read(path).lines
      if res.size > 10
        res.shift(res.size - 10)
      end
      res.join('\n')
    end

    include Neph
  end
end
