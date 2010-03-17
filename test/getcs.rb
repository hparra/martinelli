# Hector G. Parra
# hectorparra.com
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'rubygems'
require 'serialport'
require 'json'

require 'martinelli/SerialDevice'
require 'martinelli/Helpers'


params = {
  "port" => "/dev/tty.usbserial",
  "baud_rate" => 9600,
  "data_bits" => 8,
  "stop_bits" => 1,
  "parity" => SerialPort::NONE
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
        tty.printf("%s", sp.getcs(10))
        puts "\n"
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
