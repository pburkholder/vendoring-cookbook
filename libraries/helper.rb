# libraries/helper.rb:

#
# Solution 2 (lazy eval)
def http_status
  require 'excon'  # move 'require' into code not evaluated at compile time
  response = Excon.get('http://google.com/')
  response.status.to_s
end

#
# Solution 3 (detect and install if necessary during compile phase)

def ensure_gem_installed(gem_name,version,libname,run_context)
    begin
      # try and load the library
      require "#{libname}"
    rescue LoadError
      # if it can't be found, then install the gem
      Chef::Log.warn("Installing pre-req #{gem_name} from rubygems.org ..")
      gem = Chef::Resource::ChefGem.new(gem_name, run_context)
      gem.version version if version
      gem.run_action(:install)
    end
end

gem_collection = [
  { 'name'    => 'inspec',
    'version' => '=0.11.0', # give it a version if needed
    'libname' => 'train'},
  { 'name'    => 'httparty',
    'libname' => 'httparty'},  # skip the version to default to latest
  { 'name'    => 'json', # this will already be installed as part of the chef-client so it will be skipped
    'libname' => 'json'},
]

run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)

gem_collection.each do |gem|
  # during compile phase, ensure that the gem is installed
  ensure_gem_installed(gem['name'],gem['version'],gem['libname'],run_context)
  require "#{gem['libname']}"
end

def httparty_status
  response = HTTParty.get('http://google.com')
  response.code.to_s
end

def train_opts_ssh
  Train.options('ssh').to_s
end
