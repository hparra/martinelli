# SerialDevice.rb

require 'rubygems'
require 'serialport' # git://github.com/hparra/ruby-serialport.git
require 'json'

module Martinelli

  # SerialDevice is a wrapper around SerialPort
  class SerialDevice
  
    attr_reader :buffer
    attr_reader :listener
    attr_reader :params

    # Initializes a SerialDevice by parsing a JSON config.
    # It does not open serial port at this time.
    #
    # {
    #   "port": {String}
    #   "format": "ASCII" | "HEX" ,
    #   "delimiter": {String},
    #   "size": {Integer}
    #   "buffered": true | false
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

      # these may be nil! either one of the other has to be defined but not both
      #@params["delimiter"] = @params["delimiter"] #|| "\r\n"
      #@params["size"] = @params["size"]

      @params["buffered"] = @params["buffered"] && true # tricky
      @params["read_timeout"] = @params["read_timeout"] || 0
	    puts "TIMEOUT" + @params["read_timeout"].to_s
	    
      @params["make"] = @params["make"] || "Unknown Manufacturer"
      @params["model"] = @params["model"] || "Unknown Model"
      @params["description"] = @params["description"] || "No Description"
      @params["keywords"] = @params["keywords"] || []
      @params["details"] = @params["details"] || {}
      
      @buffer = "EMPTY"
      @listener = nil
      @serial_port = nil
    end
  
    # Opens connection to serial port
    # Raises ArgumentError, Errno::ENOENT, Errno::EBUSY
    def open
      if @serial_port.nil? then
        @serial_port = SerialPort.new(@params["port"], @params["baud_rate"], @params["data_bits"], @params["stop_bits"], @params["parity"])
		    @serial_port.read_timeout = @params["read_timeout"]
        #puts @serial_port.modem_params.to_s
      end
    end

    # Closes connection to serial device
    def close
      if !@serial_port.nil? then
        deafen
        @serial_port.close
        @serial_port = nil
      end
    end
    
    # Creates thread that listens for serial device output and places it in a buffer
    # Does not execute if thread already exists
    def listen
      if @listener.nil? then
        @listener = Thread.new do
          loop do
      			#sleep(0.001) # Why windows needs this, i don't know.
            @buffer = getd
			      Thread.pass
          end
        end
        @listener.run
		    $log.debug("Created new thread for " + @params["make"] + " " + @params["model"])
      end
    end

    # Returns status of listener thread
    def listening?
      return @listener != nil
    end
    
    # Stops execution of listener thread
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
    
    # "get character" a character
    def getc
      return @serial_port.getc
    end
    
    # "get characters" a string of n characters
    def getcs(n = 1)
      s = ""
      n.times do
        s += getc
      end
      return s
    end
    
    # TODO: abstract @params["delimiter"] out. Check tests first
    # "get string" a string terminated by specified delimeter
    def gets
      return @serial_port.gets(@params["delimiter"])
    end

    # "get data" a string representing device data according to rule
    def getd
      if @params["delimiter"] != nil then # defined? kept jumping into first case! WTF?
        gets
      elsif @params["size"] != nil
        getcs(@params["size"])
      else
        puts "Serious Error!" # TODO: use proper exception
      end
    end
    
    # deprecate?
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

    # Sends one character at a time to 
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