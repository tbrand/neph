def bump_version_cr(version)
  puts "Bump the version for version.cr"
  file = File.read(File.expand_path("../src/neph/version.cr", __FILE__))
  file.sub!(/VERSION = "(.+)"/, "VERSION = \"#{version}\"")
  File.write(File.expand_path("../src/neph/version.cr", __FILE__), file)
end

def bump_shard_yml(version)
  puts "Bump the version for shard.yml"
  file = File.read(File.expand_path("../shard.yml", __FILE__))
  file.sub!(/version: (.+)/, "version: #{version}")
  File.write(File.expand_path("../shard.yml", __FILE__), file)
end

abort("Failed to file a bumping version") if ARGV.size.zero?

version = ARGV[0]
puts "Bump version: #{version}"

bump_version_cr(version)
bump_shard_yml(version)
