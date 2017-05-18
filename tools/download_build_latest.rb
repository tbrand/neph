# /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/release/tools/download_build_latest.rb)"

require "fileutils"

tmp_neph = "/tmp/neph"

FileUtils.rm_rf(tmp_neph) if Dir.exist?(tmp_neph)

puts `git clone -b master https://github.com/tbrand/neph #{tmp_neph}`
puts "Building neph..."
puts `cd #{tmp_neph}; shards build --release`
