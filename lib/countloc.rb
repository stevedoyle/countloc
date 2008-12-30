# = countloc.rb - Ruby line counter.
#
# Copyright (C) 2008  Stephen Doyle
#
# == Features
# countloc.rb currently supports generating LOC metrics for Ruby source code.
#
# The following commenting styles are supported:
# * Single line comments - starting from a # until the end of the line.
# * Multi-line comments - between "=begin" and "=end" tags.
#
# == Example
# countloc.rb --help
# countloc.rb some_file.rb
#

require 'optparse'

class CountLocPatterns
  attr_reader :single_line_full   # Entire line is a single line comment
  attr_reader :single_line_mixed  # Mixed code and comment on same line
  attr_reader :multi_line_begin   # Beginning of a multi-line comment
  attr_reader :multi_line_end     # End of a multi-line comment
  
  def initialize
    @single_line_full = /^\s*#/
    @single_line_mixed = /#/
    @multi_line_begin = /=begin/
    @multi_line_end = /=end/
  end
end

# Get the lines of code (LOC) metrics for the specified filename(s).
# Returns: Metrics in the form of a hash of name-value pairs.
def countloc(filename)
  stats = { 'comments'=>0, 'code'=>0, 'blank'=>0, 'total'=>0 }
  patterns = CountLocPatterns.new
  isMultilineOpen = false
  
  srcFile = File.new(filename, 'r').each do |line|
    stats['total'] += 1
    
    if isMultilineOpen
      if line =~ patterns.multi_line_end
        isMultilineOpen = false
      end
      stats['comments'] += 1
      next
    end
    
    if line =~ /^\s*$/  # Blank line
      stats['blank'] += 1
      next
    end
    
    if line =~ patterns.multi_line_begin
      isMultilineOpen = true
      stats['comments'] += 1
      next
    end
    
    if line =~ patterns.single_line_full
      stats['comments'] += 1
      next
    end

    # Process the line to avoid matching comment characters within quoted
    # strings or regular expressions.
    line.gsub!(/\'.*?\'/, "X")  # Single quoted string
    line.gsub!(/\".*?\"/, "X")  # Double quoted string
    line.gsub!(/\/.*?\//, "X")  # Regular expression
    
    if line =~ patterns.single_line_mixed
      stats['comments'] += 1
      stats['code'] += 1
    else
      stats['code'] += 1
    end   
  end
  
  stats['code:comment'] = stats['code'].to_f / stats['comments']
  
  return stats
end
  
# When run as a standalone script ...
if $0 == __FILE__:
  usage = "Usage: #{$0} [-h --help] <file>"

  options = {}  
  OptionParser.new do |opts|
    opts.banner = usage
  end.parse!

  if ARGV.length != 1
    puts usage
    exit
  end

  stats = countloc(ARGV[0])
  stats.each { |k,v| puts "#{k} = #{v}" }
end
