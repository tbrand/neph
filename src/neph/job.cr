module Neph
  class Job
    enum Status
      # The job is not started yet.
      Waiting
      # The job has currently running commands.
      Running
    end

    # The name of the job.
    property name : String
    # The jobs that are required by this job.
    property sub_jobs : Array(Job) = [] of Job
    # The status of the job.
    property status : Status = Status::Waiting
    # The interpreter that runs the job.
    property interpreter : Interpreter = Interpreter.new
    property commands : Array(String) = [] of String

    def initialize(@name : String)
    end
  end
end
