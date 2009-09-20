
require 'martinelli/ResourceHandler'
require 'martinelli/SerialDevice'

module Martinelli
  class DevicesResourceHandler < ResourceHandler

    def initialize
      @device_handlers = Hash.new
    end
    
    def process(request, response)
      request, response = preprocess(request, response)
      content_type = "text/plain"

      $log.debug(@request_method)
      case (@request_method)
        when 'GET' # return device list
          response_code = 200
          response_content = "device list goes here"
        when 'PUT' # create device
          begin
            device_name = @parsed_request_path.last
            if (device_name == "devices") then
              throw "Bad parameter"
            end
            put_device(device_name, @body)
            response_code = 201 # "Created"
            response_content = '/devices/' + device_name + ' initialized.'
            #head["Location"] = absoluteURI
          rescue ArgumentError => err
            response_code = 400 # "Bad Request"
            response_content = 'Bad parameters: ' + err
          rescue Errno::ENOENT => e
            response_code = 400 # "Bad Request"
            response_content = "Device doesn't exist" + err
          rescue Errno::EBUSY => e
            response_code = 400 # "Bad Request"
            response_content = 'Device is in use ' + err
          end
        when 'POST' # 
          #
        when 'DELETE'
          response_code = 200 # "OK"
          response_content = 'Device disconnected.'
        when 'HEAD'
          response_code = 405
          response_content = "405: Method Not Allowed"
          head['Allow'] = "GET, PUT, POST, DELETE"
        else
          response_code = 501
          response_content = "501: Not Implemented"
      end
      
      # RESPONSE
      response.start(response_code) do |head, out|
        head["Content-Type"] = content_type
        out << response_content
      end
      
    end
    
    def put_device(device_name, device_parameters)
      $log.debug(device_name + ": " + device_parameters)
      params = JSON(device_parameters)

      device = SerialDevice.new(params["port"], params["baud"], params["data_bits"], params["stop_bits"], params["parity_bits"])
      #device.open()
      # send params to new object
      #SerialDeviceResourceHandler.new()
      
      # register handlers
      #@device_handler[""] = 
    end

  end
end