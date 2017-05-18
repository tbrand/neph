require "option_parser"
require "file_utils"
require "colorize"
require "../neph"

class NephBin
  JOB_NAME = "main"
  CONFIG_PATH = "neph.yml"

  def initialize
    ready_dir
    
    @job_name = JOB_NAME
    @config_path = CONFIG_PATH
  end
  
  def parse_option!
    OptionParser.parse! do |parser|
      parser.banner = "Usage: neph [options]"

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

      parser.on("-q", "--quiet", "Quiet mode, print out nothing") do
        @quiet = true
      end

      parser.on("-v", "--version", "Show the version") do
        log_ln VERSION
        exit 0
      end

      parser.on("-h", "--help", "Show this help") do
        log_ln parser.to_s
        exit 0
      end

      parser.unknown_args do |args|
        args.each do |arg|
          case arg
          when "clean"
            log_ln "Neph".colorize.fore(:green).mode(:bold).to_s + " is cleaning caches ..."
            clean
            exit 0
          when "uninstall"
            log_ln "Neph".colorize.fore(:green).mode(:bold).to_s + " will be uninstalled ..."
            uninstall
            exit 0
          when "update"
            log_ln "Neph".colorize.fore(:green).mode(:bold).to_s + " will be updated ..."
            exit 0
          end
        end
      end
    end
  end

  def clean
    FileUtils.rm_rf(NEPH_DIR)
  end

  def uninstall
    neph_path = `which neph`.chomp
    log_ln "Find 'neph' at #{neph_path}"

    loop do
      log_ln "Are you sure you want to uninstall 'neph'? [Y/n]"
      
      if input = STDIN.gets
        case input
        when "Y"
          log_ln "Uninstalling neph..."
          FileUtils.rm_rf(neph_path)
          log_ln "Successfully uninstalled, thanks for using 'neph' so far!"
          break
        when "n"
          log_ln "Abort the uninstallation..."
          break
        end
      end
    end
  end

  def update
    puts `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/master/tools/update.rb)"`
  end

  def exec
    main_job = parse_yaml(@job_name, @config_path)

    job_executor = JobExecutor.new(main_job)
    job_executor.exec
  end

  include Neph
end

neph_bin = NephBin.new
neph_bin.parse_option!
neph_bin.exec
