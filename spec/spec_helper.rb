$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'bundler/setup'

require 'ey_tea/server'
require 'ey_tea/client'

require 'digest/sha2'

EY::Tea::Server.mock!
Thin::Logging.debug = Thin::Logging.trace = true

RSpec.configure do |config|
  config.color_enabled = config.tty = true #Force ANSI colors

  config.around :each do |callback|
    EY::Tea::Server.reset!

    @client = EY::Tea::Client.new(:endpoint => EY::Tea::Server.mock_uri.to_s)
    callback.run
  end
end
