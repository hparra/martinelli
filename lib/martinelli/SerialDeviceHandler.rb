module Martinelli
  #
  # Serial Device Handler
  #
  class SerialDeviceHandler < ResourceHandler

    def initialize
      puts "__FILE__: " + File.dirname(__FILE__)

      @serial_devices = Hash.new
      dirname = File.dirname(__FILE__) + "/../config/"
      Dir.foreach dirname do |basename|
        filename = dirname + basename
        if File.file? filename then
          $log.debug("Opening " + filename)
          File.open(filename, "r") do |config_file|
            begin
              config = JSON(config_file.read)
              $log.debug(config)
              
              raise ArgumentError, "Resource name not specified", caller if config["name"].nil?
              raise ArgumentError, "Port not specified", caller if config["port"].nil?

              config["baud"] = config["baud"] || 2400
              config["dataBits"] = config["dataBits"] || 8
              config["stopBits"] = config["stopBits"] || 1
              config["parityBits"] = config["parityBits"] || 0
              
              serial_device = SerialDevice.new(config["port"], config["baud"], config["dataBits"], config["stopBits"], config["parityBits"], config["style"])
              serial_device.open
              if (serial_device.style == "LISTEN")
                serial_device.listen # thread
              end
              @serial_devices[config["name"]] = serial_device
              $log.info("\"" + config["name"] + "\" initialized!")
            # don't know why this isn't working
            #rescue JSON::ParserError => e
            #  $log.error("Bad JSON from " + filename)
            rescue Errno::ENOENT => e # device doesn't exist
              $log.error(config["name"] + ": " + config["port"] + " does not exist!")
            end
          end
        end
      end
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
      
      # FIXME: Design won't work if we want to stream data
      begin        
        device = nil
        if @serial_devices.has_key?(@parsed_request_path.last)
          device = @serial_devices[@parsed_request_path.last]
        end
        
        if (device.nil?) then
          response_code = 404
          response_content = "404: DEVICE NOT FOUND"
        else
          
          @request_method = @params['method']
          case (@request_method)
          when 'GET'          
            if (@data_type == JSONP) then
              callback = @params['callback']
              content_type = "application/json"
              response_code = 200
              response_content = "#{callback}({data: \"#{device.buffer.to_s.strip}\"})"
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
                puts "json data is : "
                puts @parsed_json.data
                  response_content = "LISTEN: 200 OK"
                  if(asciify(@parsed_json.data) != "")
                     device.write(@parsed_json.data)
                  end
              end
              
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
      
      # RESPONSE
      response.start(response_code) do |head, out|
        head["Content-Type"] = content_type
        out << response_content
      end
      
    end
  end
end