## Problem

You need to use Ruby code in your cookbook that's not part of chef-client Omnibus install.

While this documentation stands alone, if you really want to understand what's going on, then `git clone` this cookbook, and check out the various tags.

As simple, but contrived example, suppose you need to save an HTTP status code to a file, and you generally use the `excon` gem, so you want to run this:

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

If you try to use with test kitchen you'll get something like this:

```
> git checkout v0
> kitchen converge
....
LoadError
---------
cannot load such file -- excon
```

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

Now see how that it works:

```
> git checkout v1
> kitchen verify
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

Then test:

```
> git checkout v1
> kitchen test
....
excon-cookbook::default
  File "/tmp/status"
    content
      should match /301/

Finished in 0.07431 seconds (files took 0.26609 seconds to load)
1 example, 0 failures
```

## Solution 3: Utilize ruby exception handling to detect and optionally install the gem via Chef::Resource::ChefGem if necessary
We define an array of hashes containig gems that need to exist during the compile phase.
If they don't exist, we install them, prior to convergence.
```
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
```

## Solution 4: Use compile_time true and move library code into recipes

## Solution 5: Vendor the gem into your cookbook

## Variation 6: How to use a newer gem than what Chef Omnibus installs
