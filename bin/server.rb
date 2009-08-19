############### UNCOMMENT THIS TO START SERVER
#
#$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"
#require 'martinelli'

#server = Martinelli::SerialDeviceWebServer.new
#server.run.join
################

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"
require 'martinelli/cider_buffer'


puts "starting buffer"
buffer = CiderBuffer.new(100)
i = 0
time = Time.new.to_f
while i < 1000
  buffer.insert(i)
  i += 1
  if(rand > 0.9)
    temp = buffer.get(time)
    puts temp
    puts "end of chunk \n"
    time = Time.new.to_f
  end
end
puts "end is = " + i