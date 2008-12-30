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

# Class that gathers the metrics. 
# This class design & implementation is based heavily on Stefan Lang's 
# ScriptLines class from the "Ruby Cookbook" - Section 19.5 "Gathering 
# Statistics About Your Code".
class LineCounter
  attr_reader :name
  attr_accessor :code, :comments, :blank, :lines
  
  SINGLE_LINE_FULL_PATTERN = /^\s*#/
  SINGLE_LINE_MIXED_PATTERN = /#/
  MULTI_LINE_BEGIN_PATTERN = /=begin(\s|$)/
  MULTI_LINE_END_PATTERN = /=end(\s|$)/
  BLANK_LINE_PATTERN = /^\s*$/

  LINE_FORMAT = '%-40s %8s %8s %8s %8s'

  def self.headline
    sprintf LINE_FORMAT, "FILE", "LOC", "COMMENTS", "BLANK", "LINES"
  end
  
  def initialize(name)
    @name = name
    @code = 0
    @comments = 0
    @blank = 0
    @lines = 0
  end

  # Iterates over all the lines in io (io might be a file or a string),
  # analyzes them and appropriately increases the counter attributes.
  def read(io)
    in_multiline_comment = false
    io.each do |line| 
      @lines += 1

      # Process the line to avoid matching comment characters within quoted
      # strings or regular expressions.
      line.gsub!(/\'.*?\'/, "X")  # Single quoted string
      line.gsub!(/\".*?\"/, "X")  # Double quoted string
      line.gsub!(/\/.*?\//, "X")  # Regular expression

      case line
      when MULTI_LINE_BEGIN_PATTERN
        in_multiline_comment = true
        @comments += 1
      when MULTI_LINE_END_PATTERN
        in_multiline_comment = false
        @comments += 1
      when BLANK_LINE_PATTERN
        @blank += 1
      when SINGLE_LINE_FULL_PATTERN
        @comments += 1
      when SINGLE_LINE_MIXED_PATTERN
        @comments += 1
        @code += 1
      else
        if in_multiline_comment
          @comments += 1
        else
          @code += 1
        end
      end
    end
  end
  
  # Get a new LineCounter instance whose counters hold the sum of self
  # and other.
  def +(other)
    sum = self.dup
    sum.code += other.code
    sum.comments += other.comments
    sum.blank += other.blank
    sum.lines += other.lines
    return sum
  end
  
  # Get a formatted string containing all counter numbers and the name of
  # this instance.
  def to_s
    sprintf LINE_FORMAT, @name, @code, @comments, @blank, @lines
  end
  
end

# Wrapper function to get metrics for a single file  
def countloc(filename)
  counter = LineCounter.new(filename)
  File.open(filename) { |file| counter.read(file) }
  return counter
end

# When run as a standalone script ...
if $0 == __FILE__:
  usage = "Usage: #{File.basename($0)} [-h --help] <file>"

  options = {}  
  OptionParser.new do |opts|
    opts.banner = usage
    
    opts.on_tail('-h', '--help', 'display this help and exit') do
      puts opts
      exit
    end
    
  end.parse!

  if ARGV.length < 1
    puts usage
    exit
  end

  # Sum will keep the running total
  sum = LineCounter.new("TOTAL (#{ARGV.size} files)")
  
  puts LineCounter.headline
  
  ARGV.each do |filename|
    File.open(filename) do |file|
      counter = LineCounter.new(filename)
      counter.read(file)
      sum += counter
      puts counter
    end
  end
  
  # Print the total stats
  puts sum
  
end
