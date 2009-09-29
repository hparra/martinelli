
require 'martinelli/ResourceHandler'
require 'martinelli/SerialDevice'

module Martinelli
  class DevicesResourceHandler < ResourceHandler

    # def initialize
    #   @device_handlers = Hash.new
    # end
    
    def initialize
      puts "__FILE__: " + File.dirname(__FILE__)

      @devices = Hash.new
      
      dirname = File.dirname(__FILE__) + "/../../config/"
      Dir.foreach dirname do |basename|
        filename = dirname + basename
        if File.file? filename then
          $log.debug("Opening " + filename)
          File.open(filename, "r") do |config_file|
            begin
              response_code, response_content = create_device(nil, config_file.read)
              $log.debug("Code: " + response_code + ". Content: " + response_content)
            end
          end
        end
      end
    end
    
    def read_devices
      return @devices.to_json
    end
    
    def create_device(name, json_params) # Create => PUT
      begin
        $log.debug("DevicesResourceHandler#create_device(" + name + ", " + json_params + ")"

        params = JSON(json_params)
        if name.nil? then
          name = params["name"]
        end
        
        raise ArgumentError, "Resource name not specified", caller if name.nil?
        raise "AlreadyExistsError" if @devices.has_key?(name)
        raise ArgumentError, "Port not specified", caller if params["port"].nil?      
        
        # defaults
        params["baud"] = params["baud"] || 2400
        params["data_bits"] = params["data_bits"] || 8
        params["stop_bits"] = params["stop_bits"] || 1
        params["parity_bits"] = params["parity_bits"] || 0
        
        device = SerialDevice.new(params["port"], params["baud"], params["data_bits"], params["stop_bits"], params["parity_bits"])
        device.open
        device.listen # returns thread? or should device keep it?
        @devices[name] = device
        
        response_code = 201 # "Created"
        response_content = '/devices/' + name + ' created'
        #head["Location"] = absoluteURI
      rescue JSON::ParserError => err
        response_code = 400 # "Bad Request"
        response_content = 'Invalid JSON:' + err
      rescue "AlreadyExistsError"
        response_code = 409 # "Conflict"
        response_content = 'URI is already in use ' + err
      rescue ArgumentError => err
        response_code = 400 # "Bad Request"
        response_content = 'Bad parameters: ' + err
      rescue Errno::ENOENT => err
        response_code = 400 # "Bad Request"
        response_content = "Port doesn't exist" + err
      rescue Errno::EBUSY => err
        response_code = 409 # "Conflict"
        response_content = 'Port is already in use ' + err
      rescue
        response_code = 500
        response_content = "Unknown server error"
      end
      return response_code, response_content      
    end
    
    
    def process(request, response)
      request, response = preprocess(request, response)
      content_type = "text/plain"

      # messy routing
      if route_is_valid(request.params["REQUEST_PATH"]) then
        if route_is_device_root(request.params["REQUEST_PATH"]) then
          if @request_method == GET then
            response_code = 200
            response_content = read_devices
          else # != GET
            response_code = 405
            response_content = "/devices only supports GET"
          end
        else # may be a device
          if device_exists(request.params["REQUEST_PATH"]) then
            
          else # device does not exist
            if @request_method == PUT then
              response_code, response_content = create_device()
            else
              response_code = 404
              response_content = "device does not exist"
            end
          end
        end
      else # !route_is_valid
        response_code = 404
        response_content = "No such device. May not be valid"
      end 


      $log.debug(@request_method)
      case (@request_method)
        when 'GET' # return device list
          response_code = 200
          response_content = "device list goes here"
        when 'PUT' # create device

        when 'POST' # 
          #
        when 'DELETE'
          response_code = 200 # "OK"
          response_content = 'Device disconnected.'
        when 'HEAD'
          response_code = 405 # "Method not allowed"
          response_content = "405: Method Not Allowed"
          head['Allow'] = "GET, PUT, POST, DELETE"
        else
          response_code = 501 # "Not Implemented"
          response_content = "501: Not Implemented"
      end
      
      # RESPONSE
      response.start(response_code) do |head, out|
        head["Content-Type"] = content_type
        out << response_content
      end
      
    end

  end
end