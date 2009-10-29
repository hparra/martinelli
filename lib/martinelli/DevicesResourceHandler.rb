
require 'json'
require 'martinelli/SerialDevice'

module Martinelli
  
  # Custom Mongrel HTTP Handler for serial port device communication
  class DevicesResourceHandler < Mongrel::HttpHandler

    # Initializes DevicesResourceHandler
    # Creates devices Hash Table
    # Reads JSON files in MARTINELLI/config and calls create_device() for each
    def initialize
      @devices = Hash.new      
      dirname = File.dirname(__FILE__) + "/../../config/"
      Dir.foreach dirname do |basename|
        filename = dirname + basename
        if File.file? filename and filename.include? "json" then
          $log.debug("Opening " + filename)
          File.open(filename, "r") do |config_file|
            response_code, response_content = create_device(nil, config_file.read)
            $log.debug("CONFIG => " + response_code.to_s + " " + response_content)
          end
        end
      end
    end
    
    # Reads devices hash table
    # Returns list of devices as JSON
    # Analogous GET /devices
    def read_devices
      return 200, @devices.to_json
    end
    
    # Creates a device by opening a serial port connection
    # Returns HTTP Response Code as Integer and Response as JSON
    # * 201 if SerialDevice initialized
    # * 409 if SerialDevice port or URI is already in use
    # * 400 if SerialDevice parameters are bad due to unexistant port, malformed JSON, etc.
    # * 500 if an unknown error occured
    # Analogous to PUT /devices/{device}
    def create_device(name, json_params)
      begin

        params = JSON(json_params)
        if name.nil? then
          name = params["name"]
        end
        $log.debug("DevicesResourceHandler#create_device(" + name + ", " + json_params + ")")
        
        raise ArgumentError, "Resource name not specified", caller if name.nil?
        raise IndexError, "URI in use", caller if @devices.has_key?(name)
        raise ArgumentError, "Port not specified", caller if params["port"].nil?
        
        device = SerialDevice.new(json_params)
        device.open
		
		    # FIXME: Blocks under Win32/Ruby1.8. Don't know why
        unless device.params['mute?'] then
          device.listen # returns thread? or should device keep it?
        end
        
        @devices[name] = device
        
        response_code = 201 # "Created"
        response_content = '/devices/' + name + ' created'
        #head["Location"] = absoluteURI
      rescue JSON::ParserError => err
        response_code = 400 # "Bad Request"
        response_content = 'Invalid JSON:' + err
      rescue IndexError => err
       response_code = 409 # "Conflict"
       response_content = 'URI is already in use ' + err
      rescue ArgumentError => err
        response_code = 400 # "Bad Request"
        response_content = 'Bad parameters: ' + err
      rescue Errno::ENOENT => err
        response_code = 400 # "Bad Request"
        response_content = "Port doesn't exist: " + err
      rescue Errno::EBUSY => err
        response_code = 409 # "Conflict"
        response_content = 'Port is already in use: ' + err
      rescue Exception => err
        response_code = 500 # Server Error
        response_content = err.class.name + "#" + err.message
        $log.error(err.backtrace.join("\n"))
      end
      
      response_body = {
        "response" => response_content
      }.to_json
      
      return response_code, response_body 
    end

    # Deletes a device by closing a serial port connection
    # Returns HTTP Response Code as Integer and Response as JSON
    # * 200 if SerialDevice is closed
    # * 404 if SerialDevice does not exist
    # Analogous to DELETE /devices/{device}
    def delete_device(name)
      if @devices.has_key? name then
        @devices[name].close
        @devices.delete(name)
        response_code = 200
        response_content = "/devices/" + name + " has been deleted"
      else
        response_code = 404
        response_content = "No such device"
      end
      response_body = {
        "response" => response_content
      }.to_json
      return response_code, response_body
    end

    # Reads a device's metadata
    # See SerialDevice
    # Returns HTTP Response Code as Integer and Response as JSON
    # * 200 if SerialDevice is found
    # * 404 if SerialDevice does not exist
    # Analogous to HEAD /devices/{device}
    def read_device_metadata(name)
      if @devices.has_key? name then
        response_content = @devices[name]
        response_code = 200
      else
        response_code = 404
        response_content = "No such device"
      end      
      response_body = {
        "response" => response_content
      }.to_json
      $log.debug(response_body)
      return response_code, response_body
    end
    
    # Reads device data
    # Returns HTTP Response Code as Integer and Response as JSON
    # * 200 if SerialDevice is found
    # * 404 if SerialDevice does not exist
    # Analogous to GET /devices/{device}
    def read_device(name)
      if @devices.has_key? name then
        response_content = string_metaencode(@devices[name].buffer, @devices[name].params["format"])
        response_code = 200
      else
        response_code = 404
        response_content = "No such device"
      end      
      response_body = {
        "response" => response_content
      }.to_json
      return response_code, response_body
    end

    # Writes data to a device
    # Metadecodes ASCII representation to format device understands
    # See SerialDevice
    # Returns HTTP Response Code as Integer and Response as JSON
    # * 200 if SerialDevice is found
    # * 404 if SerialDevice does not exist
    # Analogous to POST /devices/{device}
    def update_device(name, json_body)
      if @devices.has_key? name then
          
        body = JSON(json_body) # TODO: should check for request field
        $log.debug "UPDATE:" + body["input"].dump + body["input"].length.to_s
        
        input = string_metadecode(body["input"], @devices[name].params["format"])
        
        @devices[name].putz input
        
        response_code = 200
        response_content = body["input"]
      else
        response_code = 404
        response_content = "No such device"
      end
      
      response_body = {
        "response" => response_content
      }.to_json
      
      return response_code, response_body
    end
  
    # Accepts valid HTTP 1.1 request, processes request, and sends out response
    # Only processes the following routes:
    # * HOST/devices
    # * HOST/devices/{device_name}
    # Supports overloaded GET and POST through 'method=' query
    # Supports JSONP through 'format=JSONP&callback=' query
    # Mongrel calls this method directly
    def process(request, response)
      @request_method = request.params[Mongrel::Const::REQUEST_METHOD]
      request_path = request.params["REQUEST_PATH"]
      http_host = request.params["HTTP_HOST"]
      query_string = request.params["QUERY_STRING"]
      request_string = "http://" + http_host + request_path
      request_string += ("?" + query_string) if query_string
      $log.debug("REQUEST => " + @request_method + " " + request_string)
      
      query = Mongrel::HttpRequest.query_parse(query_string)

      # overloaded request_method
      if (@request_method == GET || @request_method == POST) && query["method"] != nil then
        @request_method = query["method"]
      end
      
      # overloaded request_body
      if query["body"] != nil then
        body = query["body"]
      else
        body = request.body.string
      end

      # routing
      if DevicesResourceHandler::route_valid? request_path then
        if DevicesResourceHandler::route_devices_root? request_path then
          case @request_method
          when GET
            response_code, response_body = read_devices
          when PUT, POST, DELETE, HEAD
            response_code = 405
            response_content = "/devices only supports GET"
            response_body = {
              "response" => response_content    
            }.to_json
          else
            response_code = 501
            response_content = "501: Not implemented"
            response_body = {
              "response" => response_content
            }.to_json
          end
        else # route is valid and is not devices root
          device_name = DevicesResourceHandler::get_device_name(request_path)
          case @request_method
          when PUT
            response_code, response_body = create_device(device_name, body)
          when GET
            response_code, response_body = read_device(device_name)
          when POST
            response_code, response_body = update_device(device_name, body)
          when DELETE
            response_code, response_body = delete_device(device_name)
          when HEAD
            response_code, response_body = read_device_metadata(device_name)
          else
            response_code = 501
            response_content = "501: Not implemented"
            response_body = {
              "response" => response_content
            }.to_json
          end
        end
      else # route is invalid
        response_code = 404
        response_content = "No such device. Route may not be valid"
        response_body = {
          "response" => response_content
        }.to_json
      end
      
      content_type = "application/json"
      
      if (query['callback']) then # JSONP
        callback = query['callback']
        content_type = "application/javascript"
        response_body = "#{callback}(#{response_body})"
      end
      
      $log.debug("RESPONSE => " + response_code.to_s + " " + response_body)
      response.start(response_code) do |head, out| # RESPONSE
        head["Content-Type"] = content_type
        out << response_body
      end
    end
    
    # Takes an ASCII string with a metaencoding and converts symbols into byte literals
    # Returns 8-bit ASCII string
    def string_metadecode(text, metaencoding)
      case metaencoding
      when "ASCII"
        decoded_string = text
      when "HEX" # Ex: 50 34 1A FF
        decoded_string = ""
        tmp = text.tr(" \r\n\t", '') # TODO: Build custom non-HEX stripper
        tmp.scan(/../) do |couple|
          decoded_string += couple.hex.chr
        end
      when "BIN"
        decoded_string = ""
        tmp = text.tr(" \r\n\t", '')
        tmp.scan(/......../) do |byte|
          decoded_string += byte.to_i(2).chr
        end
      else
        raise RuntimeError
      end
      $log.debug("Metadecode: " + text.inspect + " => " + decoded_string.inspect)
      return decoded_string
    end

    # Takes an ASCII string and converts each character into a string representing the desired metaencode
    # Examples
    # * HEX: "F" => "46"
    # * OCT: "F" => "106"
    # * BIN: "F" => "001000110"
    # Returns 8-bit ASCII string
    def string_metaencode(text, metaencoding)
      case metaencoding
      when "ASCII"
        encoded_string = text
      when "HEX"
        encoded_string = text.unpack("H*").pop
      when "BIN"
        encoded_string = text.unpack("B*").pop
      else
        raise RuntimeError
      end
      $log.debug("Metaencode: " + text.inspect + " => " + encoded_string.inspect)
      return encoded_string
    end

    #
    #
    def device_exists?(name)
      return @devices.has_key?(name)
    end

    # RE: Following static funtions, I like what they abstract, but hate their implementation
    
    def self.get_device_name(request_path)
      a = request_path.split("/") # should probably use heavy regex instead
      a[0] = "/" # split will always return at least empty string due to "/"
      return a.last
    end
    
    def self.route_valid?(request_path)
      a = request_path.split("/") # should probably use heavy regex instead
      a[0] = "/" # split will always return at least empty string due to "/"
      return a.last == "devices" || a.at(-2) == "devices"
    end
    
    def self.route_devices_root?(request_path)
      a = request_path.split("/") # should probably use heavy regex instead
      a[0] = "/" # split will always return at least empty string due to "/"
      return a.last == "devices"
    end

  end
end