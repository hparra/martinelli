# SerialDevice.rb

require 'rubygems'
require 'serialport' # git://github.com/hparra/ruby-serialport.git

module Martinelli

  class SerialDevice
  
    attr_reader :buffer
    attr_reader :style
    #attr_reader :delimeter
  
    # constructor
    #
    def initialize(port, baud_rate, data_bits, stop_bits, parity)
      # TODO: Check sanity of params
      @port = port
      @baud_rate = baud_rate
      @data_bits = data_bits
      @stop_bits = stop_bits
      @parity = parity
      #@style = style
      @connected_devices = []
      @buffer = "EMPTY"
      @listener = nil
      @serial_port = nil
      @cat = ""
    end
  
    # open connection to device
    #
    def open
      if @serial_port.nil? then
        # throws ArgumentError, Errno::ENOENT, Errno::EBUSY
        @serial_port = SerialPort.new(@port, @baud_rate, @data_bits, @stop_bits, @parity)
      end
    end

    # close connection to device
    #
    def close
      if !@serial_port.nil? then
        @serial_port.close()
        @serial_port = nil
      end
    end
    
    def listen
      if (@listener.nil?)
        @listener = Thread.new do
		  $log.debug("Creating new thread!")
          loop do
			#sleep(0.1) # Why windows needs this, i don't know.
			# read timeout?
            @buffer = @serial_port.gets
			Thread.pass
          end
        end
        @listener.run
      end
      
    end
    
    
    
    def listening?
      return !@listener.nil?
    end
    
    def deaf
      if (@listener)
        @listener.exit
        @listener = null
      end
    end
    
    def flush
      @serial_port.flush()
    end
    
    def post(s)
      @serial_port.write(s)
      return @serial_port.gets
    end
    
    # writes a string
    def write(s)
      @serial_port.write(s)
    end
    
    def read
      return "Not yet implemented"
    end
    
    def getc
      return @serial_port.getc
    end
    
    # LAME!
    def slow_write(s, delay = 0.01)
      for i in 0..s.length-1
        ch = s[i..i]
        @serial_port.putc(ch)
        $log.debug("Wrote: " + ch)
        sleep(delay)
      end
    end


    # Overloaded puts. Blocks.
    #
    def puts(s)
      # standard puts does not work
      # should we send '\r' here too?
      @serial_port << s
    end

    # Overloaded gets. Blocks.
    #
    def gets(delimiter = "\r")
      @serial_port.gets(delimiter)
    end

    # get. Non-blocking.
    def q_gets
      
    end

    # hackery please fix me
    #
    def get(params)
      value = ""
      begin
        command = "g" + @wid
        Timeout::timeout(0.2) do
          @log.debug("Attempting slow_puts: " + command)
          slow_puts(command)
          response = @serial_port.gets("\n")
          @log.debug("Got: " + response)
          value = response[4..-2].chomp
        end
      rescue Timeout::Error
        value # returns last value
      end

      return value
    end

    #
    #
    def put(params)
      puts(s)
    end

    def to_json
      {
        "port" => @port,
        "baud_rate" => @baud_rate,
        "data_bits" => @data_bits,
        "stop_bits" => @stop_bits,
        "parity" => @parity
      }.to_json
    end
  
  	def to_s
  		"Hello!"
  	end
  
  end

end
# END SerialDevice.rb