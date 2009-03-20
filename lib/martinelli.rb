#!/bin/ruby

require 'rubygems'
require 'mongrel'
require 'logger'
#require 'rbconfig' # for knowing OS
require 'json'

require 'martinelli/SerialDevice'
require 'martinelli/ResourceHandler'

module Martinelli

  # Logger
  $log = Logger.new(STDOUT)
  $log.level = Logger::DEBUG
  $log.datetime_format = "%H:%M:%S"

  #
  # The WENDI Mostly-RESTful Web Service
  #
  class SerialDeviceWebServer

    def initialize(host = "0.0.0.0", port = 5000)
      
      @server = Mongrel::HttpServer.new(host, port)
      
      # FIXME: Hack for first release purposes
      #@server.register("/", Mongrel::DirHandler.new("public/bin-debug", false))
      
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
      
      response_code = 500
      content_type = "text/plain"
      response_content = "500"
      
      begin
        
        device = nil
        if @serial_devices.has_key? @parsed_request_path.last
          device = @serial_devices[@parsed_request_path.last]
        end
        if (device.nil?) then
          response_code = 404
          response_content = "404 NOT FOUND"
        else
          device = @serial_devices[@parsed_request_path.last]
          case @request_method
          when 'GET'
            response_code = 200
            response_content = "200"
          when 'HEAD'
            response_code = 501
            response_content = "501 ERROR"
          when 'PUT'
            response_code = 501
            response_content = "501 ERROR"
          when 'POST'
            if (@body != nil && @body != "") then
              device.write(hexify(@body))
            end
            response_code = 200
            response_content = "200 OK"
          when 'DELETE'
            response_code = 501
            response_content = "501 ERROR"
          else
            raise "Not a valid HTTP 1.1 REQUEST_METHOD"
          end
        end
      rescue Exception => e
        response_code = 500
        content_type = "text/plain"
        response_content = "500"
        $log.error(e)
      end
      
      response.start(response_code) do |head, out|
        head["Content-Type"] = @content_type
        out << response_content
      end
    end
  end
end