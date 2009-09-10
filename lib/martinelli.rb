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
  # The WENDI Web Service
  #
  class SerialDeviceWebServer

    def initialize(host = "0.0.0.0", port = 5000)
      
      @server = Mongrel::HttpServer.new(host, port)
      
      # FIXME: For interface testing
      @server.register("/apps", Mongrel::DirHandler.new("public", false))
      
      @device = SerialDeviceHandler.new
      @server.register("/devices", @device)
      
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
          serial_device = SerialDevice.new(i[1]["port"], i[1]["baud"], i[1]["dataBits"], i[1]["stopBits"], i[1]["parityBits"], i[1]["style"])
          serial_device.open # TODO Error Checking!
          
          if (serial_device.style == "LISTEN")
            serial_device.listen # thread
          end
          
          @serial_devices[serial_device_name] = serial_device
          
          $log.info("\"" + serial_device_name + "\" initialized!")
        rescue Errno::ENOENT => e # device doesn't exist
          $log.error(serial_device_name + ": " + i[1]["port"] + " does not exist!")
        end
      end
    end
    
 def hexify(s)
      h = ""
      s = s.chop()
      s = s.split('')
      s.each {
        |x|
        if(x == "0")
          h += x
        elsif (x.hex > 0)
          h+= x
        elsif (x.hex == 0)
          return ""
        end
      }
      return h
  end
  #    s = s.gsub(/\s/, '') # remove spaces
  #    $log.debug("Stripped: " + s)
  #    s.scan(/../).each { | tuple | h += tuple.hex.chr }
  #    return h
    end
    
    def asciify(str)
      s = ""
      str = str.chop().split('')
      str.each {
        |x|
        a = x
        if(?a > 31 && ?a < 127)
          s += a
        else
          return ""
        end
      }
      #str.scan(/./).each { |ch| s += ch }
      # error when given string "_@"
      return s
    end
    
    #
    # PROCESS
    #
    def process(request, response)
      
      request, response = preprocess(request, response)
      
      # defaults
      content_type = "text/plain"
      response_code = 500
      response_content = "500"
      device_type = "Unknown"
      
      # FIXME: Design won't work if we want to stream data
      begin
        
        device = nil
        if @serial_devices.has_key?(@parsed_request_path.last)
          device = @serial_devices[@parsed_request_path.last]
        end
        
        if (device.nil?) then
          response_code = 404
          response_content = "404 NOT FOUND"
        else
          device = @serial_devices[@parsed_request_path.last] # again?

          @request_method = @params['method']
          case (@request_method)
          when 'GET'          
            if (@data_type == JSONP) then
              callback = @params['callback']
              content_type = "application/json"
              response_code = 200

              if(@params['device_type'] == "heart")
                device.write("G1")
                puts "called G1 \n"
                puts device.buffer
                response_content = "#{callback}({data: \"#{device.buffer.to_a(' ')[2]}\"})"
              else
                puts device.buffer.to_s.strip
                response_content = "#{callback}({data: \"#{device.buffer.to_s.strip}\"})"
              end
            else
              content_type = "text/plain"
              response_code = 200
              response_content = device.buffer
            end

          # TODO: POST over JSONP. Research first. CROSS DOMAIN REQUEST !!!! TRY TO HACK SOMETHING TOGETHER !!!!
          when 'POST'
            if (@body != nil && @body != "") then

              # TODO
              # parse body (JSON)
              # check body.data_type
              # if HEX, validate, and hexify
              # if alphanumeric ASCII, validate

              @parsed_json = JSON.parse(@body)
              if(@parsed_json.data_type.to_s.upcase == "HEX")
                  response_content = "200 OK"
                  if(hexify(@parsed_json.data) != "")
                    device.write(hexify(@parsed_json.data))
                  end
              elsif(@parsed_json.data_type.to_s.upcase == "ASCII")
                puts @parsed_json.device_type.to_s
                  response_content = "LISTEN: 200 OK"
                  if(asciify(@parsed_json.data.strip) != "")
                     #device.write(asciify(@parsed_json.data.to_s))
                     device.write(@parsed_json.data.to_s.strip.sub("\n", "\r"))
                  end
              end

#              if (@body == "S")
#                device.write('S')
#                response_content = "LISTEN: 200 OK"
#              else
#                device.write(hexify(@body))
#                response_content = "200 OK"
#              end
              
            end
            response_code = 200
          when 'HEAD'
            response_code = 501
            response_content = "501 ERROR"
          when 'PUT'
            response_code = 501
            response_content = "501 ERROR"
          when 'DELETE'
            response_code = 501
            response_content = "501 ERROR"
          else
            raise "Not a valid HTTP 1.1 REQUEST_METHOD"
          end
        end
      rescue Exception => e
        content_type = "text/plain"
        response_code = 500
        response_content = "500"
        $log.error(e)
      end
      
      response.start(response_code) do |head, out|
        head["Content-Type"] = content_type
        out << response_content
      end
    end
  end