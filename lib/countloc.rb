#!/usr/bin/ruby
#
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
# == Download
# The latest countloc release can be downloaded from RubyForge: 
# http://rubyforge.org/frs/?group_id=7555&release_id=29931
#
# == Example
# * countloc.rb --help
# * countloc.rb some_file.rb
# * countloc.rb -r .
#


require 'optparse'

COUNTLOC_VERSION = '0.1.0'

# Class that gathers the metrics. 
# 
# This class design & implementation is based heavily on Stefan Lang's 
# ScriptLines class from the "Ruby Cookbook" - Recipe 19.5 "Gathering 
# Statistics About Your Code".
class LineCounter
  attr_reader :name
  attr_accessor :code, :comments, :blank, :lines
  
  SINGLE_LINE_FULL_PATTERN = /^\s*#/
  SINGLE_LINE_MIXED_PATTERN = /#/
  MULTI_LINE_BEGIN_PATTERN = /=begin(\s|$)/
  MULTI_LINE_END_PATTERN = /=end(\s|$)/
  BLANK_LINE_PATTERN = /^\s*$/

  LINE_FORMAT = '%8s %8s %8s %8s    %s'

  #
  # Generate a string that contains the column headers for the metrics
  # printed with to_s
  #
  def self.headline
    sprintf LINE_FORMAT, "LOC", "COMMENTS", "BLANK", "LINES", "FILE"
  end
  
  def initialize(name)
    @name = name
    @code = 0
    @comments = 0
    @blank = 0
    @lines = 0
  end

  # 
  # Iterates over all the lines in io (io might be a file or a string),
  # analyzes them and appropriately increases the counter attributes.
  #
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
        end # if
      end # case
    end # read
  end # class LineCounter
  
  #
  # Get a new LineCounter instance whose counters hold the sum of self
  # and other.
  #
  def +(other)
    sum = self.dup
    sum.code += other.code
    sum.comments += other.comments
    sum.blank += other.blank
    sum.lines += other.lines
    return sum
  end
  
  #
  # Get a formatted string containing all counter numbers and the name of
  # this instance.
  #
  def to_s
    sprintf LINE_FORMAT, @code, @comments, @blank, @lines, @name
  end
  
end

#
# Generates LOC metrics for the specified files and sends the results to the console.
#
def countloc(files, options = nil)
    
  # Sum will keep the running total
  sum = LineCounter.new("TOTAL")

  # Print a banner showing the column headers
  puts LineCounter.headline

  # Expand directories into the appropriate file lists
  dirs = files.select { |filename| File.directory?(filename) }
  if dirs.size > 0
    recursePattern = ("**" if options.recurse) || ""
    files -= dirs
    files += dirs.collect { |dirname| Dir.glob(File.join(dirname, recursePattern, "*.rb"))}.flatten
  end

  # Generate metrics for each file
  files.each do |filename|
    File.open(filename) do |file|
      counter = LineCounter.new(filename)
      counter.read(file)
      sum += counter
      puts counter
    end
  end
  
  # Print the total stats
  puts sum
  return sum
end

#
# When run as a standalone script ...
#
if $0 == __FILE__:
  
  require 'ostruct'
  
  class CmdLineOptParser
    
    def self.usage 
      "Usage: #{File.basename($0)} [options] <file>"
    end

    #
    # Return a structure describing the options
    #
    def self.parse(args)
      # The options set on the command line will be collected in "options"
      # Setup the defaults here
      options = OpenStruct.new
      options.recurse = false

      OptionParser.new do |opts|
        opts.banner = usage

        opts.on('-r', '--recurse', 'Recurse into subdirectories') do |r|
          options.recurse = true
        end

        opts.on('-v', '--version', 'Display version number') do 
          puts "#{File.basename($0)}, version: #{COUNTLOC_VERSION}"
          exit
        end

        opts.on_tail('-h', '--help', 'display this help and exit') do
          puts opts
          exit
        end
      
      end.parse!(args)
      
      options
    end # parse()
  end # class CmdLineOptParser
  
  options = CmdLineOptParser.parse(ARGV)
  
  if ARGV.length < 1
    puts CmdLineOptParser.usage
    exit
  end

  countloc(ARGV, options)

end
