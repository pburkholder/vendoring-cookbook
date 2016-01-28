## Problem

You need to use Ruby code in your cookbook that's not part of chef-client Omnibus install. As simple, but contrived example, suppose you need to save an HTTP status code to a file, and you generally use the `excon` gem, so you want to run this:

```
require 'excon'

def http_status
  response = Excon.get('http://google.com/')
  response.status
end

file '/tmp/status' do
  content http_status
end
```

If you try to use with

## Solution 1: Find a way to use installed code

Sidestep the whole question but not using an additional gem. E.g., replace the above code with:

```
require 'net/http'
require 'uri'

def http_status
  uri = URI('http://google.com/')
  res = Net::HTTP.get_response(uri)

  res.code
end
```
