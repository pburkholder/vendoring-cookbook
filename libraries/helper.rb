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

def ensure_gem_installed(gem_name,version,libname)
  begin
    # try and load the library
    require "#{libname}"
  rescue LoadError
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
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
    'libname' => 'train' },
  { 'name'    => 'httparty',
    'libname' => 'httparty' },  # skip the version to default to latest
  { 'name'    => 'json', # this will already be installed as part of the chef-client so it will be skipped
    'libname' => 'json' },
]

gem_collection.each do |gem|
  # during compile phase, ensure that each gem is installed
  ensure_gem_installed(gem['name'],gem['version'],gem['libname'])
  require "#{gem['libname']}"
end

def httparty_status
  response = HTTParty.get('http://google.com')
  response.code.to_s
end

def train_opts_ssh
  Train.options('ssh').to_s
end

#
# Solution 4 (use compile_time true in the consuming recipe)

begin
  require "pony"
rescue LoadError
  Chef::Log.warn "waiting to load pony"
end

def pony_perms
  Pony.permissable_options.to_s
end

#
# Solution 5 (vendor the gem into the cookbook)
$LOAD_PATH.unshift *Dir[File.expand_path('../../files/default/vendor/gems/**/lib', __FILE__)]
$LOAD_PATH.unshift *Dir[File.expand_path('..', __FILE__)]

require 'rest-client'

def rest_status
  response = RestClient.get 'http://google.com'
  response.code.to_s
end
