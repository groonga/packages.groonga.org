require "serverspec"
require "pathname"
require "net/ssh"

include SpecInfra::Helper::Ssh
include SpecInfra::Helper::DetectOS

def without_bundler
  bundler_environment_variable_names = [
    "BUNDLE_BIN_PATH",
    "BUNDLE_GEMFILE",
    "RUBYOPT",
  ]
  variables = {}
  bundler_environment_variable_names.each do |name|
    variables[name] = ENV[name]
    ENV.delete(name)
  end
  begin
    yield
  ensure
    bundler_environment_variable_names.each do |name|
      ENV[name] = variables[name]
    end
  end
end

RSpec.configure do |c|
  if ENV["ASK_SUDO_PASSWORD"]
    require "highline/import"
    c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
  else
    c.sudo_password = ENV["SUDO_PASSWORD"]
  end
  c.before :all do
    block = self.class.metadata[:example_group_block]
    file = block.source_location.first
    host = File.basename(Pathname.new(file).dirname)
    if c.host != host
      c.ssh.close if c.ssh
      c.host  = host
      options = Net::SSH::Config.for(c.host)
      user    = options[:user] || Etc.getlogin
      config = nil
      without_bundler do
        system("vagrant", "up", host)
        system("vagrant", "provision", host)
        config = `vagrant ssh-config #{host}`
      end
      if config != ""
        config.each_line do |line|
          if match = /HostName (.*)/.match(line)
            host = match[1]
          elsif  match = /User (.*)/.match(line)
            user = match[1]
          elsif match = /IdentityFile (.*)/.match(line)
            options[:keys] =  [match[1].gsub(/"/,"")]
          elsif match = /Port (.*)/.match(line)
            options[:port] = match[1]
          end
        end
      end
      c.ssh = Net::SSH.start(host, user, options)
    end
  end
end
