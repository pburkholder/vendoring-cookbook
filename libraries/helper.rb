# libraries/helper.rb:

def http_status
  require 'excon'  # move 'require' into code not evaluated at compile time
  response = Excon.get('http://google.com/')
  response.status.to_s
end
