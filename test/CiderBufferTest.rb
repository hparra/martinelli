$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"
require 'cider/CiderBuffer'


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
  if(rand(10) > 8) || i == 1000
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

puts "\ndebug info: \n"
puts time
puts buffer.getTimeEnd
puts "end of debug information\n\n"
temp = buffer.get(time)
puts temp
if (temp != nil)
  temp.pop
  if temp != []
    puts "last data chunk \n"
    puts "not nil"
    puts temp
  end
end
puts "myTime: " + time.to_s + "\n"
puts "startTime: " + buffer.getTimeStart.to_s + "\n"
puts "endTime: " + buffer.getTimeEnd.to_s + "\n"
puts "end is = " + i.to_s 