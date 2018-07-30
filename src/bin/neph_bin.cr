require "option_parser"
require "file_utils"
require "colorize"
require "../neph"

class NephBin
  JOB_NAME    = "main"
  CONFIG_PATH = "neph.yaml"
  @job_name : String = JOB_NAME
  @config_path : String = CONFIG_PATH
  @mode : String = "AUTO"

  def initialize
    ready_dir

    parse_option!

    if @mode == "AUTO"
      if STDOUT.tty?
        @mode = "NORMAL"
      else
        @mode = "CI"
      end
    end
  end

  def parse_option!
    OptionParser.parse! do |parser|
      parser.banner = "Basic usage: neph [options] [job_name]"

      parser.on(
        "-y CONFIG",
        "--yaml=CONFIG",
        "Specify a location of neph.yaml (Default is #{CONFIG_PATH})"
      ) do |config_path|
        @config_path = config_path
      end

      parser.on("-m MODE", "--mode=MODE", "Log modes [NORMAL/CI/QUIET/AUTO] (Default is AUTO)") do |mode|
        if !{"NORMAL", "CI", "QUIET", "AUTO"}.includes? mode
          log_ln "Please select mode from one of NORMAL, CI or QUIET."
          exit -1
        end

        @mode = mode
      end

      parser.on("-v", "--version", "Show the version") do
        log_ln VERSION
        exit 0
      end

      parser.on("-h", "--help", "Show this help") do
        log_ln parser.to_s
        puts "Recent incompatible changes:
    - '.yml' extension changed to '.yaml'
    - 'uninstall' action removed, because it is the job of the distro package manager
    - 'clean' action moved to '--clean'
    - '-j|--job' option removed"
        exit 0
      end

      parser.on("-c", "--clean", "Cleaning caches") do
        log_ln "Neph".colorize.fore(:green).mode(:bold).to_s + " is cleaning caches ..."
        clean
        exit 0
      end

      parser.unknown_args do |args|
        if args.size > 1
          log_ln "Only one job is supported yet."
          exit 1
        end
        @job_name = args[0] if args[0]?
      end
    end
  end

  def clean
    FileUtils.rm_rf(NEPH_DIR) if Dir.exists?(NEPH_DIR)
  end

  def exec
    main_job = parse_yaml(@job_name, @config_path)

    job_executor = JobExecutor.new(main_job, @mode)
    job_executor.exec
  end

  include Neph
end

neph_bin = NephBin.new
neph_bin.exec
