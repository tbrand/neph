# This struct stores the configuration specified in the first YAML document of neph.yaml.
# It is used only in the parser when the second document (job definitions) is parsed.
struct Neph::Config
  # The interpreter that is used to run the jobs.
  property interpreter : Job::Interpreter = Job::Interpreter.new

  # The name of the main job, that is launched when no job name is specified in the command line.
  # The default is `main`.
  property main_job : String = "main"

  # The environment variables to set when the jobs are launched.
  property environment : Hash(String, String) = {} of String => String

  # A list of paths that will be included in the config file.
  # Shell-style globs are allowed.
  property include : Array(String) = [] of String
end
