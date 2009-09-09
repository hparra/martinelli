$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"
require 'martinelli/SerialDevice'
require 'logger'

def hexify(s)
  h = ""
  s.scan(/../).each { | tuple | h += tuple.hex.chr }
  return h
end

#d = "FF".hex.chr
UP = hexify("8101060101050301FF")
DOWN = hexify("8101060101050302FF")
STOP = hexify("8101060101010303FF")
IN1 = hexify("01818181")
IN2 = hexify("01828181")

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG
$log.datetime_format = "%H:%M:%S"

begin
  @device = Martinelli::SerialDevice.new("/dev/tty.usbserial", 9600)
  @device.open
  Kernel.open("/dev/tty", "r+") do |tty|		# open terminal/console read + write
		tty.sync = true													# flush output immediately
		Thread.new do
			loop do
		  	tty.printf("%X", @device.getc)				# output data
			end
		end
		while (s = tty.getc) do							  # while there is input
      case s.chr
      when '1'
        @device.write(IN1)
      when '2'
        @device.write(IN2)
      end
		end
	end
rescue Interrupt														# catch ctrl-c
	@device.flush()
  @device.close()
end