def bump_version_cr(version)
  file_path = File.expand_path("../src/neph/version.cr", __FILE__)

  puts "Bump the version for version.cr"
  file = File.read(file_path)
  file.sub!(/VERSION = "(.+)"/, "VERSION = \"#{version}\"")
  File.write(file_path, file)

  `git add #{file_path}`
end

def bump_shard_yml(version)
  File.expand_path("../shard.yml", __FILE__)
  
  puts "Bump the version for shard.yml"
  file = File.read(file_path)
  file.sub!(/version: (.+)/, "version: #{version}")
  File.write(file_path, file)

  `git add #{file_path}`
end

abort("Failed to file a bumping version") if ARGV.size.zero?

version = ARGV[0]
puts "Bump version: #{version}"

bump_version_cr(version)
bump_shard_yml(version)
