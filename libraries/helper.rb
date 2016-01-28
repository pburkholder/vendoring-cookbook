# libraries/helper.rb:

def http_status
  require 'excon'
  response = Excon.get('http://google.com/')
  response.status.to_s
end
