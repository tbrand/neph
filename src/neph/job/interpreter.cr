# An interpreter that runs the commands of a job.
struct Neph::Job::Interpreter
  # The name of the interpreter executable.
  getter command : String

  # The arguments passed to the interpreter process.
  getter arguments : Array(String | Symbol)

  # Returns a hash with the builtin preset names as keys, and interpreters as values.
  # Currently supported builtin interpreters are:
  # - `sh`
  # - `bash`
  # - `zsh`
  # - [`elvish`](https://elvish.io)
  #
  # Elvish can't read commands from standard input,
  # so it is passed to it as an argument.
  BUILTINS = {
    "sh"     => new,
    "zsh"    => new("zsh"),
    "bash"   => new("bash"),
    "elvish" => new("elvish", ["-c", :command]),
  }

  # Creates a new instance with `sh` as the default interpreter.
  def initialize(@command : String = "sh", @arguments : Array(String | Symbol) = [] of String | Symbol)
  end
end
