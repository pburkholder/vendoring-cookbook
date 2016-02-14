## TL;DR

clone this cookbook and run `kitchen converge` to see all the examples implemented at once.

## Problem Statement

You need to use a Ruby gem in your cookbook libarary that is not part of chef-client Omnibus install.

For example, you write a library that uses the 'excon' gem.

```
# libraries/helper.rb:
require 'excon'

def http_status
  response = Excon.get('http://google.com/')
  response.status
end
```

```
# recipes/default.rb:
file '/tmp/status' do
  content http_status
end
```

When you attempt to converge the node, you receive this compile time error:

```
LoadError
---------
cannot load such file -- excon
```

The helper.rb library fails to compile because the `excon` library doesn't exist yet.

## Solution 1: Find a way to use already-installed code

Sidestep the whole question but not using an additional gem. E.g., replace the above code with:

```
# libraries/helper.rb:
require 'net/http'
require 'uri'

def http_status
  uri = URI('http://google.com/')
  res = Net::HTTP.get_response(uri)
  res.code
end
```

## Solution 2: Install gem with `chef_gem`; then use `lazy` eval

One way to address this is look at the `content` attribute of our `file` resource:

```
  content http_status
```

During the chef-client _compilation_ phase, the client will try to build a `file` object with the `content` attribute defined. However, we can leave that attribute undefined until the _convergence_ phase by using [lazy evalutation](https://docs.chef.io/resource_common.html#lazy-evaluation), like this:

```
  content lazy { http_status }
```

To do this, first change the helper to not `require` anything during the initial code pass by moving `require 'excon'` into the method `def`:

```
# libraries/helper.rb:

def http_status
  require 'excon'  # move 'require' into code not evaluated at compile time
  response = Excon.get('http://google.com/')
  response.status.to_s
end
```

Then we'll use the `chef_gem` resource to install `excon` during the _convergence_ phase, since the Excon code isn't needed until we do the _lazy evaluation_.  *And* we'll use the `lazy` keyword with the `content` attribute:

```
# recipes/default.rb
chef_gem 'excon' do
  compile_time false
  action :install
end

file '/tmp/status' do
  content lazy { http_status }
end
```

## Solution 3: Utilize ruby exception handling to detect and optionally install the gem via Chef::Resource::ChefGem if necessary

We implement a helper method to facility gem install during the compile phase.
```
# libraries/helper.rb:

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

# enumerate the gems you depend upon
gem_collection = [
  { 'name'    => 'inspec',
    'version' => '=0.11.0', # give it a version if needed
    'libname' => 'train' },
  { 'name'    => 'httparty',
    'libname' => 'httparty' },  # skip the version to default to latest
  { 'name'    => 'json', # this will already be installed as part of the chef-client so it will be skipped
    'libname' => 'json' },
]

run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)

gem_collection.each do |gem|
  # during compile phase, ensure that each gem is installed
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
```

Use the library methods in your recipe:
```
file '/tmp/httparty' do
  content httparty_status
end

file '/tmp/train_opts_ssh' do
  content train_opts_ssh
end
```

## Solution 4: Use chef_gem compile_time true and move library require into recipe

We rescue LoadError in the library and in the consuming recipe we use a `chef_gem` resource with `compile_time true`
```
begin
  require "pony"
rescue LoadError
  Chef::Log.warn "waiting to load pony"
end

def pony_perms
  Pony.permissable_options.to_s
end
```

In the recipe:
```
chef_gem 'pony' do
  compile_time true
end

require 'pony'

file '/tmp/pony' do
  content pony_perms
end
```

## Solution 5: Vendor the gem into your cookbook
The implementation entails installing the gem into your cookbook. In the Ruby world, this process is referred to as "vendoring a gem."

For instance, to vendor the rest-client gem in your cookbook root:
```
gem install --no-rdoc --no-ri --install-dir files/default/vendor --no-user-install rest-client
```

The next step is to manipulate the `$LOAD_PATH` so that the chef-client run will search the cookbook path to find the library.
```
# libraries/helper.rb:

$LOAD_PATH.push *Dir[File.expand_path('../../files/default/vendor/gems/**/lib', __FILE__)]
$LOAD_PATH.unshift *Dir[File.expand_path('..', __FILE__)]

require 'rest-client'

def rest_status
  require 'rest-client'
  response = RestClient.get 'http://google.com'
  response.code.to_s
end
```

NOTE:  This approach has a few caveats.
 - potential cookbook bloat if the gem has several dependencies
 - if the gem builds native extensions then this is not a good strategy
 - if the gem you're installing is already part of the chef-client (ex. the "json" gem), then the json library from the chef-client install is ALWAYS used instead of the vendored one.  This is because the chef-client already has the "json" gem activated prior to loading the one from the vendored path.  The only way to workaround is the following, using `reject`:

```
$LOAD_PATH.reject! {|item| item =~ /json-/ } # this removes '/opt/chef/embedded/lib/ruby/gems/2.1.0/gems/json-1.8.3/lib'
$LOAD_PATH.push *Dir[File.expand_path('../../files/default/vendor/gems/**/lib', __FILE__)]
$LOAD_PATH.unshift *Dir[File.expand_path('..', __FILE__)]
```
