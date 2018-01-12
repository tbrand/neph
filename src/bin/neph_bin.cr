require "option_parser"
require "file_utils"
require "colorize"
require "../neph"

class NephBin
  JOB_NAME    = "main"
  CONFIG_PATH = "neph.yml"

  def initialize
    ready_dir

    @options = {
      "mode" => "NORMAL",
    }

    @job_name = JOB_NAME
    @config_path = CONFIG_PATH
  end

  def parse_option!
    OptionParser.parse! do |parser|
      parser.banner = "Basic usage: neph [options]"

      parser.on(
        "-j JOB",
        "--job=JOB",
        "Specify a job name to be executed (Default is  #{JOB_NAME})"
      ) do |job_name|
        @job_name = job_name
      end

      parser.on(
        "-y CONFIG",
        "--yml=CONFIG",
        "Specify a location of neph.yml (Default is #{CONFIG_PATH})"
      ) do |config_path|
        @config_path = config_path
      end

      parser.on("-m MODE", "--mode=MODE", "Log modes [NORMAL/CI/QUIET] (Default is NORMAL)") do |mode|
        if mode != "NORMAL" && mode != "CI" && mode != "QUIET"
          log_ln "Please select mode from one of NORMAL, CI or QUIET."
          exit -1
        end

        @options["mode"] = mode
      end

      parser.on("-v", "--version", "Show the version") do
        log_ln VERSION
        exit 0
      end

      parser.on("-h", "--help", "Show this help") do
        log_ln parser.to_s
        log_ln "Action: neph [action]"
        log_ln "    neph clean     - Cleaning every caches"
        exit 0
      end

      parser.unknown_args do |args|
        args.each do |arg|
          case arg
          when "clean"
            log_ln "Neph".colorize.fore(:green).mode(:bold).to_s + " is cleaning caches ..."
            clean
            exit 0
          end
        end
      end
    end
  end

  def clean
    FileUtils.rm_rf(NEPH_DIR) if Dir.exists?(NEPH_DIR)
  end

  def exec
    main_job = parse_yaml(@job_name, @config_path)

    job_executor = JobExecutor.new(main_job, @options)
    job_executor.exec
  end

  include Neph
end

neph_bin = NephBin.new
neph_bin.parse_option!
neph_bin.exec
