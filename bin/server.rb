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
buffer = CiderBuffer.new(500)
i = 0
time = Time.new.to_f
while i < 1000
  buffer.insert(i)
  i += 1
  if(rand(10) > 8)
    temp = buffer.get(time)
    time = Time.new.to_f
    if temp == nil
      puts "time is syncronizing"
    else
      puts temp
      puts "end of chunk \n"
    end
  end
end
puts "myTime: " + time.to_s + "\n"
puts "startTime: " + buffer.getTimeStart.to_s + "\n"
puts "endTime: " + buffer.getTimeEnd.to_s + "\n"
puts "last data chunk \n"
puts buffer.get(time)
puts "end is = " + i.to_s