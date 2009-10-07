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
  "baud_rate" => ARGV[1].to_i || 2400,
  "data_bits" => ARGV[2] || 8,
  "stop_bits" => ARGV[3] || 1,
  "parity" => ARGV[4].to_i || SerialPort::NONE,
  "delimiter" => ARGV[5] || "\r\n"
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
        tty.printf("%s", sp.gets)
        puts "\n"
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
    
    while (c = tty.gets) do                 # while there is input
      sp.putz(c)
    end
    # loop do                 # while there is input
    #   sleep(1)
    #   sp.putz("V\r")
    # end
  end
rescue Interrupt                            # catch ctrl-c
  sp.flush                                  # flush one last tlsime
  sp.close                                  # close serial connection
end
