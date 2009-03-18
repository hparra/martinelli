

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"
require 'martinelli'

server = Martinelli::SerialDeviceWebServer.new
server.run.join