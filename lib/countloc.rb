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
require 'time'

#
# CountLOC module that encapsulates the methods and classes used to gather
# code metrics.
#
module CountLOC

  VERSION = '0.2.0'

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

    LINE_FORMAT = '%8s %8s %8s %8s %12s    %s'

    #
    # Generate a string that contains the column headers for the metrics
    # printed with to_s
    #
    def self.headline
      sprintf LINE_FORMAT, "LOC", "COMMENTS", "BLANK", "LINES", "CODE:COMMENT", "FILE"
    end

    #
    # Return an array containing the column names for the counters collected.
    #
    def self.columnNames
      self.headline.split(' ', 6)
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
      codeCommentRatio = (sprintf "%0.2f", @code.to_f/@comments if @comments > 0) || '--'
      sprintf LINE_FORMAT, @code, @comments, @blank, @lines, codeCommentRatio, @name
    end

    #
    # Get a formatted string containing all counter numbers and the name of
    # this instance.
    #
    def to_a
      self.to_s.split(' ', 6)
    end

  end

  #
  # Container class to store results from each file.
  #
  class Results < Array

    # Return a string containing all the results.
    def to_s
      str = LineCounter.headline + "\n"
      self.each { |result| str += result.to_s + "\n"}
      str
    end

    # Return a string containing all the results in csv format.
    # The first row is a header row of the column names.
    # Each subsequent row corresponds to a result from the results array.
    def to_csv
      csvString = LineCounter.columnNames.join(',') + "\n"
      self.each { |result| csvString += result.to_a.join(',')  + "\n"}
      csvString
    end

    # Return a string containing the results formatted as a html table.
    # The first row is a header row of the column names.
    # Each subsequent row corresponds to a result from the results array.
    def to_html
      htmlString = %{<table border="1" cellspacing="0" cellpadding="2">}
      htmlString += %{<tr>}
      LineCounter.columnNames.each { |name| htmlString += %{<th>#{name}</th>} }
      htmlString += %{</tr>}
      self.each do |result|
        htmlString += %{<tr>}
        result.to_a.each { |cell| htmlString += %{<td>#{cell}</td> } }
        htmlString += %{</tr>}
      end
      htmlString += %{</table>}
      htmlString += %{<p><em>Generated by } +
      %{<a href="http://countloc.rubyforge.org">countloc</a> version #{VERSION} } +
      %{on #{Time.now.asctime}</em></p>}
    end

  end

  #
  # Class that writes to the Console
  #
  class ConsoleWriter
    # Write the data to the console
    def write(data)
      puts data
    end  
  end

  #
  # Class that writes to a csv file
  #
  class CsvFileWriter

    def initialize(filename)
      @filename = filename
    end

    # Write the csv file, including the data contents (via 
    # the to_csv method on the data)
    def write(data)
      begin
        File.open(@filename, "wb") { |file| file.puts data.to_csv }
      rescue 
        puts "Error: " + $!
      end    
    end

  end

  #
  # Class that writes to a html file
  #
  class HtmlFileWriter

    def initialize(filename)
      @filename = filename
    end

    # Write the html file, including the data contents (via 
    # the to_html method on the data)
    def write(data)
      begin
        File.open(@filename, "w") { |file| file.puts data.to_html }
      rescue 
        puts "Error: " + $!
      end    
    end

  end

  #
  # Generates LOC metrics for the specified files and sends the results to the console.
  #
  def countloc(files, options = nil)

    # Setup the output writers based on the options
    writers = [ConsoleWriter.new]
    writers << CsvFileWriter.new(options.csvFilename) if options.csv
    writers << HtmlFileWriter.new(options.htmlFilename) if options.html

    # Expand directories into the appropriate file lists
    dirs = files.select { |filename| File.directory?(filename) }
    if dirs.size > 0
      recursePattern = ("**" if options.recurse) || ""
      files -= dirs
      files += dirs.collect { |dirname| Dir.glob(File.join(dirname, recursePattern, "*.rb"))}.flatten      
    end

    # Sum will keep the running total
    sum = LineCounter.new("TOTAL")

    # Container to hold the results
    results = Results.new

    # Generate metrics for each file
    files.each do |filename|
      begin
        File.open(filename) do |file|
          counter = LineCounter.new(filename)
          counter.read(file)
          sum += counter
          results << counter
        end
      rescue
        puts "Error: " + $!
      end
    end

    # Add the totals to the results
    results << sum

    # Write the metrics to the required files in the appropriate formats
    writers.each { |writer| writer.write(results) }

    return results
  end
  
  module_function :countloc

end # module

#
# When run as a standalone script ...
#
if $0 == __FILE__:

  require 'ostruct'

  class CmdLineOptParser

    def self.usage 
      "Usage: #{File.basename($0)} [-h|--help] [options] <file> ... <file>"
    end

    #
    # Return a structure describing the options
    #
    def self.parse(args)
      # The options set on the command line will be collected in "options"
      # Setup the defaults here
      options = OpenStruct.new
      options.recurse = false
      options.csv = false
      options.csvFilename = ""
      options.html = false
      options.htmlFilename = ""

      begin
        OptionParser.new do |opts|
          opts.banner = usage

          opts.on('-r', '--recurse', 'Recurse into subdirectories') do
            options.recurse = true
          end

          opts.on('-v', '--version', 'Display version number') do 
            puts "#{File.basename($0)}, version: #{VERSION}"
            exit
          end

          opts.on('--csv csvFilename', 'Generate csv file') do |csvFilename|
            options.csvFilename = csvFilename
            options.csv = true
          end

          opts.on('--html htmlFilename', 'Generate html file') do |htmlFilename|
            options.htmlFilename = htmlFilename
            options.html = true
          end

          opts.on_tail('-h', '--help', 'Display this help and exit') do
            puts opts
            exit
          end

        end.parse!(args)

      rescue
        puts "Error: " + $!
        exit
      end

      options
    end # parse()
  end # class CmdLineOptParser

  options = CmdLineOptParser.parse(ARGV)

  if ARGV.length < 1
    puts CmdLineOptParser.usage
    exit
  end

  CountLOC.countloc(ARGV, options)

end
