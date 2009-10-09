
require 'json'
require 'martinelli/ResourceHandler'
require 'martinelli/SerialDevice'

module Martinelli
  class DevicesResourceHandler < ResourceHandler

    def initialize
      #puts "__FILE__: " + File.dirname(__FILE__)

      @devices = Hash.new # should probably use another structure
      
      # load config files
      dirname = File.dirname(__FILE__) + "/../../config/"
      Dir.foreach dirname do |basename|
        filename = dirname + basename
        if File.file? filename and filename.include? "json" then
          $log.debug("Opening " + filename)
          File.open(filename, "r") do |config_file|
            response_code, response_content = create_device(nil, config_file.read)
            $log.debug("(" + response_code.to_s + ") " + response_content)
          end
        end
      end
    end
    
    #
    # GET /devices
    def read_devices
      return @devices.to_json
    end
    
    #
    # PUT /devices/{device}
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
        device.listen # returns thread? or should device keep it?
        @devices[name] = device
        
        response_code = 201 # "Created"
        response_content = '/devices/' + name + ' created'
        #head["Location"] = absoluteURI
      #rescue JSON::ParserError => err
      #  response_code = 400 # "Bad Request"
      #  response_content = 'Invalid JSON:' + err
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
        response_content = err.message + err.backtrace.join("\n")
      end
      
      response_body = {
        "response" => response_content
      }.to_json
      
      return response_code, response_body 
    end

    #
    # DELETE /devices/{device}
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

    #
    # HEAD /devices/{device}
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

    #
    # GET /devices/{device}
    def read_device(name)
      if @devices.has_key? name then
        response_content = @devices[name].buffer
        $log.debug(response_content.inspect)
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

    #
    # POST /devices/{device}
    def update_device(name, json_body)
      if @devices.has_key? name then
        
        body = JSON(json_body) # TODO: should check for request field
        $log.debug "UPDATE:" + body["input"].dump + body["input"].length.to_s
        @devices[name].putz body["input"]
        
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
  
    #
    #
    def process(request, response)
      request, response = preprocess(request, response)
      
      content_type = "application/json"
      query = Mongrel::HttpRequest.query_parse(request.params["QUERY_STRING"])

      # request method
      @request_method = request.params[Mongrel::Const::REQUEST_METHOD] || GET
      if @request_method == GET && query["method"] != nil then
        @request_method = query["method"]
      end
      
      # request body
      if query["body"] != nil then
        body = query["body"]
      else
        body = request.body.string
      end
      $log.debug("method=" + @request_method)
      $log.debug("body=" + body)

      # messy routing
      request_path = request.params["REQUEST_PATH"]
      if DevicesResourceHandler::route_valid? request_path then
        if DevicesResourceHandler::route_devices_root? request_path then
          case @request_method
          when GET
            response_code = 200
            response_body = read_devices
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
      
      # JSONP
      if (@data_type == JSONP) then
        callback = @params['callback']
        content_type = "application/javascript"
        response_body = "#{callback}(#{response_body})"
      end
      
      # RESPONSE
      response.start(response_code) do |head, out|
        head["Content-Type"] = content_type
        out << response_body
      end
      
    end

    def device_exists?(name)
      return @devices.has_key?(name)
    end

    # RE: Following static funtions
    # I like what they abstract, but hate their implementation
    
    def self.get_device_name(request_path)
      a = request_path.split("/") # should probably use heavy regex instead
      a[0] = "/" # split will always return at least empty string due to "/"
      return a.last
    end
    
    def self.route_valid?(request_path)
      a = request_path.split("/") # should probably use heavy regex instead
      a[0] = "/" # split will always return at least empty string due to "/"
      $log.debug(a)
      return a.last == "devices" || a.at(-2) == "devices"
    end
    
    def self.route_devices_root?(request_path)
      a = request_path.split("/") # should probably use heavy regex instead
      a[0] = "/" # split will always return at least empty string due to "/"
      return a.last == "devices"
    end

  end
end