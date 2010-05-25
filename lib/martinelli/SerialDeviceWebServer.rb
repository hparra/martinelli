require 'rubygems'
require 'mongrel'
require 'logger'
#require 'rbconfig' # for knowing OS

require 'martinelli/DevicesResourceHandler'
require 'martinelli/Helpers'

module Martinelli

  # Logger
  $log = Logger.new(STDOUT)
  $log.level = Logger::DEBUG
  $log.datetime_format = "%H:%M:%S"

  # The WENDI Web Service
  class SerialDeviceWebServer

    #
    def initialize(host = "0.0.0.0", port = 5000)
      @server = Mongrel::HttpServer.new(host, port)
      @devices_handler = DevicesResourceHandler.new
      @server.register("/devices", @devices_handler)

      @server.register("/apps", Mongrel::DirHandler.new("public", false))
      @server.register("/vendor", Mongrel::DirHandler.new("public/vendor", false))
      @server.register("/testing", Mongrel::DirHandler.new("public/testing", false))      

    end

    #
    def run
      $log.info("Starting Martinelli...")
      return @server.run
    end
  end
end
