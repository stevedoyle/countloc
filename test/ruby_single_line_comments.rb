# This is a sample piece of ruby code to test countloc with single 
# line comments. 
puts "Hello World"

# And some more code ...
1.upto(10) { |x|puts x}
 
# And yet more ...
('a'..'z').each do |alpha|
  puts alpha  # This is an example of mixed code and comments. 
end

if "abcdefg".include? "#"
  puts "We should never get here!"
end

if "abcdefg" =~ /#/
  puts "We should never get here!"
end

if "abcdefg" =~ /#/   # This is mixed also!
  puts "We should never get here!"
end
