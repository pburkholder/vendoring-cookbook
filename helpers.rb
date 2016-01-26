#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'pry'

response = RestClient.get 'https://api.github.com/users/pburkholder'

binding.pry
