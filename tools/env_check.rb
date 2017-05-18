# /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/release/tools/env_check.rb)"

def check_cmd(cmd)
  puts "Checking #{cmd} ..."
  !`which #{cmd}`.empty?
end

abort "Failed to find `git` command" unless check_cmd("git")
abort "Failed to find `crystal` command (https://github.com/crystal-lang/crystal)" unless check_cmd("crystal")
abort "Failed to find `shards` command (https://github.com/crystal-lang/shards)" unless check_cmd("shards")
