require 'json'

@current_version = ""
@new_version = ""

def update_version
  file_path = File.expand_path("../../src/neph/version.cr", __FILE__)
  file = File.read(file_path)

  if /^.*\"(\d\.\d\.\d)\".*$/ =~ file
    @current_version = $1
    versions = @current_version.split('.')
    patch_version = versions.last.to_i + 1
    @new_version = versions[0..-2].join('.') + '.' + patch_version.to_s
    return
  end

  abort "Failed to parse current version"
end

def bump_version_cr
  file_path = File.expand_path("../../src/neph/version.cr", __FILE__)

  file = File.read(file_path)
  file.sub!(/VERSION = \"(.+)\"/, "VERSION = \"#{@new_version}\"")

  File.write(file_path, file)
  `git add #{file_path}`
end

def bump_shard_yml
  file_path = File.expand_path("../../shard.yml", __FILE__)
  
  file = File.read(file_path)
  file.sub!(/version: (.+)/, "version: #{@new_version}")

  File.write(file_path, file)
  `git add #{file_path}`
end

# Update current version
update_version

# Bump versions
bump_version_cr
bump_shard_yml

tag = 'v' + @new_version

`git config --global user.name "Travis CI"`
`git config --global user.email "travis@travis-ci.org"`
`git commit -m "[skip ci] bumped version #{@new_version}"`
`git push https://#{ENV['GH_TOKEN']}@github.com/tbrand/neph.git HEAD:master`
`git push https://#{ENV['GH_TOKEN']}@github.com/tbrand/neph.git HEAD:release`
`git tag #{tag} -a -m "Release from Travis CI for build number $TRAVIS_BUILD_NUMBER"`
`git push --quiet https://#{ENV['GH_TOKEN']}@github.com/tbrand/neph.git --tags 2> /dev/null`
