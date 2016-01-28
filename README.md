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

## Solution 1: Find a way to use installed code

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
