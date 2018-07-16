class Neph::Job
  enum Status
    # The job is not started yet.
    Waiting
    # The job has currently running commands.
    Running
    # All commands finished successfully.
    Finished
  end

  @@data_dir : String = ".neph/"

  # The name of the job.
  property name : String
  # The jobs that are required by this job.
  property sub_jobs : Array(Job) = [] of Job
  # The status of the job.
  property status : Status = Status::Waiting
  # The interpreter that runs the job.
  property interpreter : Interpreter = Interpreter.new
  property commands : Array(String) = [] of String
  # If the job is required by multiple jobs, and this variable is `true`, then
  # the commands are evaluated each time the job is launched.
  property repeat : Bool = false
  property ignore_error : Bool = false
  property sequential : Bool = false
  property environment : Hash(String, String) = {} of String => String
  property before_command : String = ""
  property after_command : String = ""

  @waiting : Array(Channel::Buffered(Nil)) = [] of Channel::Buffered(Nil)
  @error : Nil | String = nil

  def initialize(@name : String)
  end

  # Get the `@@data_dir` class variable.
  def data_dir
    @@data_dir
  end

  # Set the `@@data_dir` class variable.
  def data_dir=(dir : String)
    # Add a '/' to the end of the string if there isn't.
    @@data_dir = dir + (dir[-1] == '/' ? "" : "/")
  end

  # Wait for the job to finish.
  def wait
    return @error if @status.finished?
    channel = Channel::Buffered(Nil).new 1
    @waiting << channel
    channel.receive
    @waiting.delete channel
    return @error
  end

  def run
    wait if @status.running?

    return if (@status.finished? && !@repeat) || @error

    # Create job directory.
    Dir.mkdir_p @@data_dir + @name

    # Open the log files, where the stderr and stdout will be
    # redirected of each command.
    # If the job has been finished in the current session, then append
    # the output to the log files, otherwise clear them before writing.
    log_out = File.open @@data_dir + @name + "/out.txt", mode: @status.finished? ? "a" : "w"
    log_err = File.open @@data_dir + @name + "/err.txt", mode: @status.finished? ? "a" : "w"

    @status = Status::Running

    # Run all sub jobs in separate fibers, and wait for them.
    @sub_jobs.each do |job|
      spawn { job.run }
      if @sequential
        @error = job.wait
        return if @error
      end
    end
    # If jobs are launched sequentially then it has no effect,
    # because the result is already checked in the previous block.
    @sub_jobs.each do |job|
      @error = job.wait
      return if @error
    end

    # Run the commands.
    @commands.each do |command|
      # Replace every Symbol with the command.
      arguments = @interpreter.arguments.map do |i|
        i.is_a?(Symbol) ? before_command + command + after_command : i
      end

      # Launch the process. stdout, and stderr are redirected to the log files, and a pipe is opened to input (to print the command).
      proc = Process.new @interpreter.command, arguments, env: @environment, input: Process::Redirect::Pipe, output: log_out, error: log_err

      proc.input.print command if @interpreter.arguments.none? &.is_a? Symbol
      proc.input.close

      exit_status = proc.wait
      unless exit_status.success? || @ignore_error
        if exit_status.signal_exit?
          @error = "The following command in the `#{@name}` job was terminated by SIG#{exit_status.exit_signal}:\n#{command}"
          return
        else
          @error = "The following command in the `#{@name}` job exited with #{exit_status.exit_code}:\n#{command}"
          return
        end
      end
    end
  rescue exception
    @error = exception.message
  ensure
    # Close log files
    log_out.try &.close
    log_err.try &.close

    @status = Status::Finished

    # Send signal to all jobs that are waiting for this.
    @waiting.each &.send nil
  end
end
