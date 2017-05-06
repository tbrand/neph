require "option_parser"
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
        "-c CONFIG",
        "--config=CONFIG",
        "Specify a location of neph.yml (Default is #{CONFIG_PATH})"
      ) do |config_path|
        @config_path = config_path
      end

      parser.on("-v", "--version", "Show the version") do
        puts VERSION
        exit 0
      end

      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit 0
      end
    end
  end

  def exec
    channel = Channel(Job).new
    
    neph_job = NephJob.new
    neph_job.add_sub_job(parse_yaml(@job_name, @config_path))

    spawn do
      neph_job.exec(channel)
    end

    print_status(neph_job)

    if neph_job.status_code == 0
      puts "\nFinished in #{neph_job.elapsed_time}".colorize.mode(:bold)
    else
      puts "\nError with exit code #{neph_job.status_code}".colorize.mode(:bold)
    end
  end

  def print_status(job : Job)
    prev_lines = 0

    loop do
      prev_lines = print_status(job, prev_lines)

      if job.done?
        job.fin
        print_status(job, prev_lines)
        break
      end

      sleep STATUS_CHECK_INTERVAL
    end
  end

  def print_status(job : Job, prev_lines) : Int32
    status_msg = job.to_s
    print_status(status_msg, prev_lines)
    status_msg.lines.size
  end

  def print_status(msg : String, prev_lines : Int32)
    print "\e[#{prev_lines}A" if prev_lines > 0
    puts "\e[J#{msg}"
  end

  include Neph
end

neph_bin = NephBin.new
neph_bin.parse_option!
neph_bin.exec
