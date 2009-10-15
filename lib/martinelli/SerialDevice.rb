# SerialDevice.rb

require 'rubygems'
require 'serialport' # git://github.com/hparra/ruby-serialport.git
require 'json'

module Martinelli

  class SerialDevice
  
    attr_reader :buffer
    attr_reader :listener
    attr_reader :params
  
    # {
    #   "port": {String}
    #   "format": "ASCII" | "HEX" ,
    #   "delimeter": {String},
    #   "baud_rate": [0, 100000],
    #   "data_bits": [6, 8],
    #   "stop_bits": 0 | 1 | 2,
    #   "parity": 0 | 1,
    #   "make": {String},
    #   "model": {String},
    #   "description": {String},
    #   "keywords": [{String}*],
    #   "details": {
    #     ({String}: {String})*
    #   }
    # }
    def initialize(json_object)
      @params = JSON(json_object)

      # @params["port"] required
      @params["baud_rate"] = @params["baud_rate"] || 2400
      @params["data_bits"] = @params["data_bits"] || 8
      @params["stop_bits"] = @params["stop_bits"] || 1
      @params["parity"] = @params["parity"] || 0
      
      @params["format"] = @params["format"] || "ASCII"
      @params["delimiter"] = @params["delimiter"] || "\r\n"
      
      # Maybe we want to leave these as empty strings?
      @params["make"] = @params["make"] || "Unknown Manufacturer"
      @params["model"] = @params["model"] || "Unknown Model"
      @params["description"] = @params["description"] || "No Description"
      @params["keywords"] = @params["keywords"] || []
      @params["details"] = @params["details"] || {}
      
      @buffer = "EMPTY"
      @listener = nil
      @serial_port = nil
    end
  
    # open connection to device
    #
    def open
      if @serial_port.nil? then
        # throws ArgumentError, Errno::ENOENT, Errno::EBUSY
        @serial_port = SerialPort.new(@params["port"], @params["baud_rate"], @params["data_bits"], @params["stop_bits"], @params["parity"])        
        puts @serial_port.modem_params.to_s
      end
    end

    # close connection to device
    #
    def close
      if !@serial_port.nil? then
        deafen
        @serial_port.close
        @serial_port = nil
      end
    end
    
    def listen
      if (@listener.nil?)
        @listener = Thread.new do
		      $log.debug("Creating new thread for " + @params["make"] + " " + @params["model"])
          loop do
			#sleep(0.1) # Why windows needs this, i don't know.
			# read timeout?
            @buffer = gets
			      #Thread.pass
          end
        end
        @listener.run
      end
    end

    def listening?
      return @listener != nil
    end
    
    def deafen
      if (@listener)
        $log.debug("Deafening listener...")
        @serial_port.flush
        @listener.exit
        @listener = nil
      end
    end
    
    def flush
      @serial_port.flush
    end
    
    def getc
      return @serial_port.getc
    end
    
    def gets
      return @serial_port.gets(@params["delimiter"])
    end
    
    def getz
      s = ""
      loop do
        c = @serial_port.getc
        
        # TODO: Check for multicharacter delimeters
        #$log.debug("Ack! " + s)
        if c.chr == @params["delimiter"] then
         return s
        end
        
        s += c.chr
      end
    end

    def putz(s)
      s.each_byte do |ch|
        @serial_port.putc(ch)
        @serial_port.flush
        #$log.debug("Wrote: " + ch.chr)
      end
    end

    def to_json
      return @params.to_json
    end
  
  	def to_s
  		return to_json
  	end
  
  end

end
# END SerialDevice.rb