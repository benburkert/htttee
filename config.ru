$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'htttee/server'

use Rack::CommonLogger
run EY::Tea::Server.app
