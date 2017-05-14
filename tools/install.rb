require "fileutils"

def check_cmd(cmd)
  puts "Checking #{cmd} ..."
  !`which #{cmd}`.empty?
end

abort "Failed to find git command" unless check_cmd("git")
abort "Failed to find crystal command (https://github.com/crystal-lang/crystal)" unless check_cmd("crystal")
abort "Failed to find shards command (https://github.com/crystal-lang/shards)" unless check_cmd("shards")

tmp_neph = "/tmp/neph"
usr_local_bin = "/usr/local/bin"

FileUtils.rm_rf(tmp_neph) if Dir.exist?(tmp_neph)

`git clone -b release https://github.com/tbrand/neph #{tmp_neph}`

puts "Building neph..."

`cd #{tmp_neph}; shards build --release`

puts "Install neph into #{usr_local_bin}"

Dir.mkdir(usr_local_bin) unless Dir.exist?(usr_local_bin)

if File.exist?("#{usr_local_bin}/neph")
  puts "neph is already installed, will be updated"
  FileUtils.rm("#{usr_local_bin}/neph")
end

FileUtils.copy("#{tmp_neph}/bin/neph", usr_local_bin)

version = `#{usr_local_bin}/neph --version`.chomp

puts "Done. (version: #{version})"
puts "If `neph` is not found, please do `export $PATH=$PATH:/usr/local/bin`"
