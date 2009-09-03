#! /usr/bin/ruby

# Hector G. Parra
# hectorparra.com

# see Ruby SerialPort README for details
require 'rubygems'
require 'serialport'



 def hexify(s)
      h = ""
      s = s.split('')
      s.each {
        |x|
        if(x == "0")
          h += x
        end
        if (x.hex > 0)
          h+= x
        else
          return ""
        end
      }
      return h
  end

#TODO: Add data_type param e.g. 'HEX', 'ASCII', et al.
data_type = ARGV[0] # required

# device (required)
port_str = ARGV[1]

# device options
baud_rate = 9600
if(defined? ARGV[2]) then
  baud_rate = ARGV[2].to_i # usually 9600
end


data_bits = 8
stop_bits = 1
parity = SerialPort::NONE

# create connection
sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

# output device info
puts "Ruby Serial Port Version #{SerialPort::VERSION}"
sp.modem_params().each {|key, value| puts "#{key} is #{value}"}

# terminal emulation
begin
	Kernel.open("/dev/tty", "r+") do |tty|		# open terminal/console read + write
		tty.sync = true													# flush output immediately
		Thread.new do
      loop do
			  #sleep (0.1)
		  	#tty.printf("%X", sp.getc)						# output data
        # TODO: Print hex if HEX, etc
        if(data_type.to_s.upcase == "HEX")
          tty.printf("%s", sp.gets.to_i(16))
        else
           tty.printf("%s", sp.gets)
        end
			end
		end
		while (s = tty.gets) do 								# while there is input
      # TODO: Write hex if HEX, etc.
      if(data_type.to_s.upcase == "HEX")
        s = hexify(s)
        if(s != "")
         sp.write(s.sub("\n", "\r").to_i(16)) # send line
        else
          puts "Error Non valid text"
        end
      else
         sp.write(s.sub("\n", "\r"))
      end
			#s.scan(/../).each { | tuple | sp.putc tuple.hex.chr }
		end
	end
rescue Interrupt														# catch ctrl-c
	sp.flush																	# flush one last tlsime
	sp.close																	# close serial connection
end