module Neph
  class NephJob < Job
    def initialize
      @s = Time.now
      super top_banner, ""
    end
    
    def status_msg
      progress_bar
    end

    def exec_self
      # do nothing
    end

    def create_dir
      # do nothing
    end

    def progress_bar : String
      percent_bar = ("|" * (progress_percent/2)).colorize.fore(:green)
      percent_bar_empty = ("|" * (50-progress_percent/2)).colorize.fore(:dark_gray)
      "#{percent_bar}#{percent_bar_empty}"
    end

    # Override
    def progress_max
      num_of_jobs-1
    end

    def top_banner
      "Running neph".colorize.fore(:green).mode(:bold).to_s+ " (#{VERSION})"
    end

    def fin
      @elapsed_time = format_time(Time.now - @s)
    end
  end
end
