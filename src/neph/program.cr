class Program
  include Neph
  @filename = "neph.yaml"
  @job_name : String?

  def run
    # Set up a command line option parser.
    opt_parser = OptionParser.new
    opt_parser.banner = "Usage: neph [options] [job name]"
    opt_parser.on "-h", "--help", "Show this help message" { STDERR.puts opt_parser; exit 0 }
    opt_parser.unknown_args do |before, after|
      # Concatenate the two arrays (arguments before and after `--` argument).
      args = before + after
      if args.size > 1
        raise OptionParser::Exception.new "Only 1 job is supported."
      end
      @job_name = args.first?
    end
    opt_parser.missing_option do |option|
      raise OptionParser::Exception.new "Option needs an argument: `#{option}`."
    end

    # If an exception is raised during command line argument
    # parsing, print its error message in red, then print a
    # help message, then exit with 1.
    begin
      opt_parser.parse!
    rescue exception : OptionParser::Exception
      STDERR.puts exception.message.colorize.red
      STDERR.puts opt_parser
      exit 1
    end

    # If an exception is raised during build file parsing, the exit code is 2.
    begin
      job = Parser.new(@filename, @job_name).parse
      p job
    rescue exception
      # Any exception that is raised during the parsing.
      STDERR.puts exception.message.colorize.red
      exit 2
    end

    # If an exception is raised during running the jobs, the exit code is 3.
    begin
      job.run
    rescue exception
      STDERR.puts exception.message.colorize.red
      exit 3
    end
  end
end
