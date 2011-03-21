$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'ey_tea/server'
require 'ey_tea/client'

require File.join(File.dirname(__FILE__), 'tea_helper')

EY::Tea::Server.mock!

RSpec.configure do |config|
  config.color_enabled = config.tty = true #Force ANSI colors
  config.include TeaHelper

  config.around :each do |callback|
    run do
      EM::Protocols::Redis.connect.flush_all
      @server_client = Rack::Client::Base.new EY::Tea::Server.app
      callback.run
    end
  end
end
