$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'ey_tea/server'

use Rack::CommonLogger
run EY::Tea::Server.app
