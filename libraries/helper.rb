# libraries/helper.rb:
require 'excon'

def http_status
  response = Excon.get('http://google.com/')
  response.status
end
