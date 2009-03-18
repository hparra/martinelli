#! /usr/bin/ruby

# Hector G. Parra
# hectorparra.com

# see Ruby SerialPort README for details
require 'rubygems'
require 'serialport'

# device
port_str = ARGV[0]

# device options
baud_rate = ARGV[1].to_i
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
			  sleep (0.1)
		  	#tty.printf("%X", sp.getc)						# output data
		  	#tty.printf("%c", sp.getc)
			end
		end
		while (s = tty.gets) do 								# while there is input
			#sp.write(s.sub("\n", "\r"))						# send line
			s.scan(/../).each { | tuple | sp.putc tuple.hex.chr }
		end
	end
rescue Interrupt														# catch ctrl-c
	sp.flush																	# flush one last time
	sp.close																	# close serial connection
end