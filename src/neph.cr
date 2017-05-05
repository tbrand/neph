require "./neph/*"

module Neph
  include Neph::Parser
  include Neph::Message
  
  NEPH_DIR = ".neph"
  NEPH_LOG_DIR = "#{NEPH_DIR}/log"

  LOG_OUT = "log.out"
  LOG_ERR = "log.err"

  STATUS_CHECK_INTERVAL = 0.1

  alias YHash = Hash(YAML::Type, YAML::Type)
  alias YArray = Array(YAML::Type)

  def neph_dir
    NEPH_DIR
  end

  def neph_log_dir
    NEPH_LOG_DIR
  end

  def log_out
    LOG_OUT
  end

  def log_err
    LOG_ERR
  end

  def ready_dir
    Dir.mkdir(neph_dir) unless Dir.exists?(neph_dir)
    Dir.mkdir(neph_log_dir) unless Dir.exists?(neph_log_dir)
  end
end
