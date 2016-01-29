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

## Solution 3: Use compile_time true and move library code into recipes

## Solution 4: Vendor the gem into your cookbook

## Variation 5: How to use a newer gem than what Chef Omnibus installs
