# CiderBuffer.rb
# Implemented by Jakkree Janchoi
# calIT2 Telios project @ University of California, Irvine


##############################
# CiderBuffer Implementation #
##############################
class CiderBuffer
  def initialize(maxSize)
    @maxBufferSize = maxSize
    @buffer = Array.new(maxSize) # containing Node
    @bufferSize = 0
    @conntectedDevices = 0
    @end = 0 #index of input from device.
    @start = 0 #index of oldest data in the buffer.
    @lastValue = 0
    @isEmpty = true
  end
  def getTimeStart()
    return @buffer.at(@start).time_value
  end
  def getTimeEnd()
    return @buffer.at(@lastValue).time_value
  end
  ################################
  # get returns array of data back to the client
  # returns array of size 2 containing [dataArray, lastPullTime]
  def get(prevTime)
    #RETRIEVE DATA FROM BUFFER
    #Return data from lastPullTime to latestInput
    if prevTime > @buffer.at(@lastValue).time_value
      return nil
    else 
      i = find_index(prevTime)
      result = Array.new()
      if i != nil
        while @buffer[i] != nil && @buffer[i] != @buffer[@end]
          if i == @maxBufferSize-1
            result.push(@buffer.at(i).value)
            i = 0
          else
            result.push(@buffer.at(i).value)
            i += 1
          end
        end
      end
    end
    result.push(Time.new.to_f)
    return result
  end

  def getNew()
      result = nil
      i = @start
      result = Array.new()
      if i != nil
        while @buffer[i] != @buffer[@end]
          if i == @maxBufferSize-1
            result.push(@buffer.at(i).value)
            i = 0
          else
            result.push(@buffer.at(i).value)
            i += 1
          end
        end
      end
    result.push(Time.new.to_f)
    return result
  end
  
  ################################
  # finds where the start index is to pull data from
  #
  def find_index(find)
      i = @start
      while  @buffer.at(i) != nil  && @buffer.at(i) != @buffer.at(@end)
        if i == @maxBufferSize
          i = 0
        end
        if @buffer.at(i) != nil  && @buffer.at(i).time_value >= find
          return i
        end
        i += 1
      end
      return nil
  end
  
  ################################
  # insert data to the buffer
  #  
  def insert(value)
   a = Node.new(value,Time.now.to_f)
   @buffer.insert(@end, a)
   @lastValue = @end
   @end += 1
   if @end == @maxBufferSize
     @end = 0
     @start += 1
   end
   if @end == @start && @buffer[@start+1] != nil
     @start += 1
   end
  end

  
## end of class
end


######################################
# Start of Node class implementation #
######################################
class Node
  def initialize(v,t)
   @receiveTime = t
   @value = v
   def time_value
     return @receiveTime
   end
   def value
     return @value
   end
  end
end