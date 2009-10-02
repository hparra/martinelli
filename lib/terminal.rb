#! /usr/bin/ruby

# Hector G. Parra
# hectorparra.com

require 'rubygems'
require 'serialport'
require 'json'

require 'martinelli/SerialDevice'
require 'martinelli/Helpers'

# USAGE
# ruby SerialDeviceTest.rb port baud_rate data_bits stop_bits parity


params = {
  "port" => ARGV[0].to_s, # required
  "format" => ARGV[1] || "ASCII",
  "delimeter" => ARGV[2] || "\r",
  "baud_rate" => ARGV[3] || 2400,
  "data_bits" => ARGV[4] || 8,
  "stop_bits" => ARGV[5] || 1,
  "parity" => ARGV[6].to_i || SerialPort::NONE
}.to_json

# create connection
puts params
sp = Martinelli::SerialDevice.new(params)
sp.open

# output device info
puts sp

# terminal emulation
begin
  Kernel.open("/dev/tty", "r+") do |tty|    # open terminal/console read + write
    tty.sync = true                         # flush output immediately
    # reading
    t = Thread.new do
      loop do
        tty.printf("%s", sp.getz)
        #tty.printf("%X", sp.getc)            # output data
        # TODO: Print hex if HEX, etc
        # if(params["format"].to_s.upcase == "HEX")
        #   tty.printf("%s", sp.gets.to_i(16))
        # else
        #   #TODO FIX THIS PROBLEM WITH GETC
        #   tty.printf("%s", sp.gets)
        # end
      end
    end
    t.join
    
    # while (s = tty.gets) do                 # while there is input
    #   # TODO: Write hex if HEX, etc.
    #   if(params["format"].to_s.upcase == "HEX")
    #     s = hexify(s)
    #     if(s != "")
    #      sp.write(s.sub("\n", "\r").to_i(16)) # send line
    #     else
    #       puts "Error, invalid character"
    #     end
    #   else # If ASCII then do this.
    #      sp.write(s.sub("\n", "\r"))
    #   end
    #   #s.scan(/../).each { | tuple | sp.putc tuple.hex.chr }
    # end
  end
rescue Interrupt                            # catch ctrl-c
  sp.flush                                  # flush one last tlsime
  sp.close                                  # close serial connection
end
