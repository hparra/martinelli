#!/bin/ruby

require 'rubygems'
require 'mongrel'
require 'logger'
require 'rbconfig' # for knowing OS
require 'json'

require 'martinelli/SerialDevice'

module Martinelli

  # Logger
  $log = Logger.new(STDOUT)
  $log.level = Logger::DEBUG
  $log.datetime_format = "%H:%M:%S"

  #
  # The WENDI RESTful Web Service
  #
  class SerialDeviceWebServer

    def initialize(host = "0.0.0.0", port = 5000)
      
      $log.debug("Starting server")
      @server = Mongrel::HttpServer.new(host, port)
      
      @device = SerialDeviceHandler.new
      @server.register("/resources/devices", @device)
      
    end

    def run
      return @server.run
    end

  end
  
  class SerialDeviceManager
    def initialize
    end
  end
  
  #
  # Serial Device Handler
  #
  class SerialDeviceHandler < Mongrel::HttpHandler
    def initialize
      @device = Martinelli::SerialDevice.new("/dev/tty.usbserial", 9600)
      @device.open
    end
    
    def hexify(s)
      h = ""
      s = s.gsub(/\s/, '')
      $log.debug("Stripped: " + s)
      s.scan(/../).each { | tuple | h += tuple.hex.chr }
      return h
    end
    
    def asciify(str)
      s = ""
      str.scan(/./).each { |ch| s += ch }
      return s
    end
    
    def process(request, response)
      begin
        response.start(200) do |head, out|
          head["Content-Type"] = "text/plain"
          body = request.body.string
          $log.debug("BODY: " + body)
          data = hexify(body) # FIXME: ask me what i need please
          @device.write(data)
          out << "OK"
        end
      rescue Exception => e
        response.start(500) do |head, out|
          head["Content-Type"] = "text/plain"
          out << "500: " + e
        end
      end
    end
  end
end