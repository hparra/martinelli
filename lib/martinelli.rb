#!/bin/ruby

require 'rubygems'
require 'mongrel'
require 'logger'
#require 'rbconfig' # for knowing OS
require 'json'

require 'martinelli/SerialDevice'
require 'martinelli/ResourceHandler'
require 'martinelli/DevicesResourceHandler'
require 'martinelli/SerialDeviceHandler'
require 'martinelli/Helpers'

module Martinelli

  # Logger
  $log = Logger.new(STDOUT)
  $log.level = Logger::DEBUG
  $log.datetime_format = "%H:%M:%S"

  #
  # The WENDI Web Service
  #
  class SerialDeviceWebServer

    def initialize(host = "0.0.0.0", port = 5000)
      
      @server = Mongrel::HttpServer.new(host, port)
      
      # FIXME: For interface testing
      @server.register("/apps", Mongrel::DirHandler.new("public", false))
      @server.register("/testing", Mongrel::DirHandler.new("public/testing", false))
      
      @devices_handler = DevicesResourceHandler.new
      @server.register("/devices", @devices_handler)
      
    end

    def run
      $log.info("Starting Martinelli...")
      return @server.run
    end

  end

end 