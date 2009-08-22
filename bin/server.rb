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
bool = true
while i < 1000
  buffer.insert(i)
  i += 1
  if(bool)
    bool = false
    temp = buffer.getNew()
    if temp == nil
      puts "time is syncronizing"
    else
      time = temp.pop
      puts temp
      puts "end of chunk \n"
    end
  end
  if(rand(10) > 8)
    temp = buffer.get(time)
    if temp == nil
      puts "time is syncronizing"
    else
      time = temp.pop
      puts temp
      puts "end of chunk \n"
    end
  end
end
temp = buffer.get(time)
if (temp != nil)
  puts "not nil"
  temp.pop
end
puts "myTime: " + time.to_s + "\n"
puts "startTime: " + buffer.getTimeStart.to_s + "\n"
puts "endTime: " + buffer.getTimeEnd.to_s + "\n"
puts "last data chunk \n"
puts temp
puts "end is = " + i.to_s