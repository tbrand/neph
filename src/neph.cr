require "./neph/*"

module Neph
  include Neph::Parser
  include Neph::Message

  NEPH_DIR = ".neph"

  LOG_OUT = "log.out"
  LOG_ERR = "log.err"

  STATUS_CHECK_INTERVAL = 0.1

  @quiet = false

  alias YHash  = Hash(YAML::Type, YAML::Type)
  alias YArray = Array(YAML::Type)

  def neph_dir
    NEPH_DIR
  end

  def log_out
    LOG_OUT
  end

  def log_err
    LOG_ERR
  end

  def ready_dir
    Dir.mkdir(neph_dir) unless Dir.exists?(neph_dir)
  end

  def format_time(time)
    minutes = time.total_minutes
    return "#{minutes.round(2)}m" if minutes >= 1

    seconds = time.total_seconds
    return "#{seconds.round(2)}s" if seconds >= 1

    millis = time.total_milliseconds
    return "#{millis.round(2)}ms" if millis >= 1

    "#{(millis * 1000).round(2)}µs"
  end

  def log_ln(msg : String, force : Bool = false)
    log(msg + "\n", force)
  end

  def log(msg : String, force : Bool = false)
    print msg if !@quiet || force
  end
end
