#!/bin/ruby

require 'rubygems'
require 'mongrel'
require 'logger'
require 'rbconfig' # for knowing OS
require 'json'

require 'martinelli/SerialDevice'
require 'martinelli/ResourceHandler'

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
      
      @server = Mongrel::HttpServer.new(host, port)
      
      @device = SerialDeviceHandler.new
      @server.register("/resources/devices", @device)
      
    end

    def run
      $log.info("Starting Martinelli...")
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
  class SerialDeviceHandler < ResourceHandler

    def initialize
      
      config_file = "config/serialdevices.json"
      # TODO File error checking
      config_file = File.open(config_file, "r")
      # TODO JSON Parsing error checking
      config = JSON(config_file.read)
      config_file.close
      
      @serial_devices = Hash.new
      
      # SerialDevice should check sanity of params
      for i in config
        $log.debug(i)
        begin
          serial_device_name = i[0]
          serial_device = SerialDevice.new(i[1]["port"], i[1]["baud"], i[1]["dataBits"], i[1]["stopBits"])
          serial_device.open # TODO Error Checking!
          @serial_devices[serial_device_name] = serial_device
          $log.info("\"" + serial_device_name + "\" initialized!")
        rescue Errno::ENOENT => e # device doesn't exist
          $log.error(serial_device_name + ": " + i[1]["port"] + " does not exist!")
        end
      end
    end
    
    def hexify(s)
      h = ""
      s = s.gsub(/\s/, '') # remove spaces
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
      preprocess(request, response)
      
      begin
        response.start(200) do |head, out|
          # INPUT
          body = request.body.string
          $log.debug("BODY: " + body)
          data = hexify(body) # FIXME: ask me what i need please
          
          # OUTPUT
          head["Content-Type"] = "text/plain"
          #@device.write(data)
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