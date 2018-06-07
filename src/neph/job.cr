class Neph::Job
  enum Status
    # The job is not started yet.
    Waiting
    # The job has currently running commands.
    Running
    # The job is finished
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
  @waiting : Array(Channel::Buffered(Nil)) = [] of Channel::Buffered(Nil)

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
  def wait(from = "self")
    return if @status.finished?
    channel = Channel::Buffered(Nil).new 1
    @waiting << channel
    channel.receive
    @waiting.delete channel
  end

  def run
    wait if @status.running?

    return if @status.finished? && !@repeat

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
    end
    @sub_jobs.each &.wait(@name)

    # Run the commands.
    @commands.each do |command|
      # Check if the interpreter accepts command on stdin, or as an argument.
      if @interpreter.arguments.any? &.is_a? Symbol
        # Replace every Symbol with the command.
        arguments = @interpreter.arguments.map do |i|
          i.is_a?(Symbol) ? command : i
        end

        Process.run @interpreter.command, arguments, output: log_out, error: log_err
      else
        # Launch the process. stdout, and stderr are redirected to the log files, and a pipe is opened to input (to print the command).
        proc = Process.new @interpreter.command, @interpreter.arguments.map(&.as String), input: Process::Redirect::Pipe, output: log_out, error: log_err

        proc.input.print command
        proc.input.close

        proc.wait
      end
    end

    # Close log files
    log_out.close
    log_err.close

    @status = Status::Finished

    # Send signal to all jobs that are waiting for this.
    @waiting.each &.send nil
  end
end
