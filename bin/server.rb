############### UNCOMMENT THIS TO START SERVER
#
#$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"
#require 'martinelli'

#server = Martinelli::SerialDeviceWebServer.new
#server.run.join
################

require 'martinelli/cider_buffer'


puts "starting buffer"
buffer = CiderBuffer.new(100)
i = 0
time = Time.new.to_f
while i < 1000
  buffer.insert(i)
  i += 1
  if(rand > 0.5)
    temp = buffer.get(time)
    ## buffer.get returns [data, lastTime]
    puts temp[0]
    time = temp[1]
  end
end