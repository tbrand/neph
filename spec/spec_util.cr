def neph_install
  puts "Installing neph..."
  `shards build --release`
end

def neph_clean
  `./bin/neph --clean`
end

def exec_neph(config_file : String, job_name : String)
  base_path = File.expand_path("../configs", __FILE__)
  `./bin/neph -y #{base_path}/#{config_file} -j #{job_name}`
end

def exec_neph(config_file : String)
  base_path = File.expand_path("../configs", __FILE__)
  `./bin/neph -y #{base_path}/#{config_file}`
end

def stdout_of(job_name : String) : String
  path = File.expand_path("../../.neph/#{job_name}/log/log.out", __FILE__)
  return File.read(path) if File.exists?(path)
  ""
end
