module Neph
  class JobExecutor

    def initialize(@job : Job); end

    def exec(@mode : String)
      channel = Channel(Job).new
      @start = Time.now

      spawn do
        @job.exec(channel)
      end
      print_status
    end

    def banner : String
      title + " " + progress_bar + "\n"
    end

    def title : String
      "Neph".colorize.fore(:green).mode(:bold).to_s + " is running (#{VERSION})"
    end

    def progress_bar : String
      percent_text = "#{progress_percent}%".colorize.fore(:green).mode(:bold)
      percent_bar = ("|" * (progress_percent/2)).colorize.fore(:green)
      percent_bar_empty = ("|" * (50-progress_percent/2)).colorize.fore(:dark_gray)
      "#{percent_bar}#{percent_text}#{percent_bar_empty}"
    end

    def progress_percent : Int32
      percent = ((progress.to_f/progress_max.to_f) * 100.0).to_i
    end

    def progress_max : Int32
      @job.progress_max
    end

    def progress : Int32
      @job.progress
    end

    def print_status
      case @mode
      when "NORMAL"
        print_status_normal
      when "CI"
        print_status_ci
      when "QUIET"
        print_status_quiet
      end
    end

    def print_status_normal
      prev_lines = 0

      loop do
        prev_lines = print_status(prev_lines)

        if @job.done?
          print_status(prev_lines)
          print_result
          break
        end

        sleep STATUS_CHECK_INTERVAL
      end
    end

    def print_status_ci
      loop do
        print @job.to_s_ci

        if @job.done?
          print_result
          break
        end

        sleep STATUS_CHECK_INTERVAL
      end
    end

    def print_status_quiet
      loop do
        break if @job.done?
        sleep STATUS_CHECK_INTERVAL
      end
    end

    def print_status(prev_lines) : Int32
      status_msg = banner + @job.to_s
      print_status(status_msg, prev_lines)
      status_msg.lines.size
    end

    def print_status(msg : String, prev_lines : Int32)
      STDOUT.print "\e[#{prev_lines}A" if prev_lines > 0
      STDOUT.print "\e[J#{msg}"
      STDOUT.flush
    end

    def print_result
      if start = @start
        elapsed_time = format_time(Time.now - @start.as(Time))
        log_ln "\nFinished in #{elapsed_time}".colorize.mode(:bold).to_s
      end
    end

    include Neph
  end
end
