require "colorize"

module Neph
  module Message
    def error(msg : String)
      "[Error]".colorize.fore(:red).to_s + " #{msg}"
    end
  end
end
