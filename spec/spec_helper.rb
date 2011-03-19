$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'ey_tea/server'
require 'ey_tea/client'

EY::Tea::Server.mock!

RSpec.configure do |config|
  config.color_enabled = config.tty = true #Force ANSI colors

  config.around :each do |callback|
    EM.synchrony do
      @server_client = Rack::Client.new { run EY::Tea::Server.app }
      callback.run
      EM.stop
    end
  end
end
