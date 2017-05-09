def new_version
  file_path = File.expand_path("../src/neph/version.cr", __FILE__)
  file = File.read(file_path)

  if /^.*\"(\d\.\d\.\d)\".*$/ =~ file
    current_version = $1
    versions = current_version.split('.')
    patch_version = versions.last.to_i + 1
    new_version = versions[0..-2].join('.') + '.' + patch_version.to_s
    return new_version
  end

  abort "Failed to parse current version"
end

def bump_version_cr(version)
  file_path = File.expand_path("../src/neph/version.cr", __FILE__)

  file = File.read(file_path)
  file.sub!(/VERSION = \"(.+)\"/, "VERSION = \"#{version}\"")

  File.write(file_path, file)
  `git add #{file_path}`
end

def bump_shard_yml(version)
  file_path = File.expand_path("../shard.yml", __FILE__)
  
  file = File.read(file_path)
  file.sub!(/version: (.+)/, "version: #{version}")

  File.write(file_path, file)
  `git add #{file_path}`
end

version = new_version

bump_version_cr(version)
bump_shard_yml(version)

print version
