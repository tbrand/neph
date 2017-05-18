``# /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/master/tools/update.rb)"

# env_check.rb
puts `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/master/tools/env_check.rb)"`

loop do
  puts "Which version will you install? [stable/latest]"
  print "> "
  if input = STDIN.gets
    case input.chomp
    when "stable"
      # download_build_stable
      puts `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/master/tools/download_build_stable.rb)"`
      break
    when "latest"
      # download_build_latest
      puts `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/master/tools/download_build_latest.rb)"`
      break
    end
  end
end

# copy_tmp_neph
puts `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/master/tools/copy_tmp_neph.rb)"`

