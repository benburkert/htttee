$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'ey_tea/server'
require 'ey_tea/client'

EY::Tea::Server.mock!

RSpec.configure do |config|
  config.color_enabled = config.tty = true #Force ANSI colors

  config.around do |callback|
    EM.synchrony do
      callback.call
      EM.stop
    end
  end

  config.before :all do
    @server_client = Rack::Client.new { run EY::Tea::Server.app }
  end
end
