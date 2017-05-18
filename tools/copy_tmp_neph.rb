# /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/release/tools/copy_tmp_neph.rb)"

require "fileutils"

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
