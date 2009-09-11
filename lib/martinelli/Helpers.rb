module Martinelli
  def hexify(s)
    h = ""
    s = s.chop()
    s = s.split('')
    s.each do |x|
      if (x == "0") then
        h += x
      elsif (x.hex > 0)
        h+= x
      elsif (x.hex == 0)
        return ""
      end
    end
    return h
  end
   #    s = s.gsub(/\s/, '') # remove spaces
   #    $log.debug("Stripped: " + s)
   #    s.scan(/../).each { | tuple | h += tuple.hex.chr }
   #    return h

  def asciify(str)
    s = ""
    str = str.chop().split('')
    str.each do |x|
      a = x
      if(?a > 31 && ?a < 127) then
        s += a
      else
        return ""
      end
    end
    #str.scan(/./).each { |ch| s += ch }
    # error when given string "_@"
    return s
  end
  
end