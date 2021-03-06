#!/usr/bin/ruby
#
# = countloc.rb - Ruby line counter.
#
# Copyright (C) 2008  Stephen Doyle
#
# == Features
# countloc.rb generates LOC metrics for a variety of programming languages.
#
# == Download
# The latest countloc release can be downloaded from RubyForge: 
# http://rubyforge.org/frs/?group_id=7555&release_id=29931
#
# == Example
# * countloc --help
# * countloc some_file.rb
# * countloc -r .
#

require 'optparse'
require 'time'

#
# CountLOC module that encapsulates the methods and classes used to gather
# code metrics.
#
module CountLOC

  VERSION = '0.4.0'

  DEFAULT_FILE_TYPES = {
      :ruby   => [".rb"],
      :python => [".py"],
      :c      => [".h", ".c"],
      :cpp    => [".h", ".hpp", ".cpp", ".c", ".cc", ".inl"],
      :csharp => [".cs"],
      :java   => [".java"],
      :vb     => [".vb"]
  }

  DEFAULT_STYLE = {
    ".rb"   => :ruby,
    ".py"   => :python,
    ".h"    => :cpp,
    ".c"    => :cpp,
    ".hpp"  => :cpp,
    ".cpp"  => :cpp,
    ".cc"   => :cpp,
    ".inl"  => :cpp,
    ".cs"   => :csharp,
    ".java" => :java,
    ".vb"   => :vb
  }

  # Get the supported style for a given filename
  def getStyle(filename)
    DEFAULT_FILE_TYPES.invert[File.extname(filename)]
  end

  # Class that gathers the metrics. 
  # 
  # This class design & implementation is based heavily on Stefan Lang's 
  # ScriptLines class from the "Ruby Cookbook" - Recipe 19.5 "Gathering 
  # Statistics About Your Code".
  class LineCounter
    attr_reader :name
    attr_accessor :code, :comments, :blank, :lines

    def comment_patterns(style)
      patterns = {
        :ruby => {
          :single_line_full => /^\s*#/,
          :single_line_mixed => /#/,
          :multiline_begin => /=begin(\s|$)/,
          :multiline_end => /=end(\s|$)/,
          :blank_line => /^\s*$/
        },
      
        :vb => {
          :single_line_full => /^\s*\'/,
          :single_line_mixed => /\'/,
          :multiline_begin => /=begin(\s|$)/, # No VB multi-line comment
          :multiline_end => /=end(\s|$)/,     # No VB multi-line comment
          :blank_line => /^\s*$/
        },

        :python => {
          :single_line_full => /^\s*#/,
          :single_line_mixed => /#/,
          :multiline_begin => /^\s*"""/,
          :multiline_end => /"""/,
          :blank_line => /^\s*$/
        },

        :cpp => {                           # C++ 
          :single_line_full => /^\s*\/\//,
          :single_line_mixed => /\/\//,
          :multiline_begin => /\/\*/,
          :multiline_end => /\*\/\s*$/,
          :multiline_begin_mixed => /^[^\s]+.*\/\*/,
          :multiline_end_mixed => /\*\/\s*[^\s]+$/,
          :blank_line => /^\s*$/
        }
      }
      patterns[:c] = patterns[:cpp]
      patterns[:csharp] = patterns[:cpp]
      patterns[:java] = patterns[:cpp]
      
      patterns[style]
    end

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
    def read(io, style)
      in_multiline_comment = false
      io.each do |line| 
        @lines += 1

        # Process the line to avoid matching comment characters within quoted
        # strings or regular expressions.
        line.gsub!(/\'.*?\'/, "X")  # Single quoted string
        line.gsub!(/[^\"]\"[^\"]+\"/, "X")  # Double quoted string
        if style == :ruby
          line.gsub!(/\/.*?\//, "X")  # Regular expression
        end

        patterns = comment_patterns(style)
        
        # In the event where the multiline_end pattern is the same as the 
        # multiline_begin pattern, it is necessary to check for the ending
        # pattern first - otherwise we will never detect the ending pattern.
        if in_multiline_comment
          if patterns.include?(:multiline_end_mixed) and 
            line =~ patterns[:multiline_end_mixed]
            @comments += 1
            @code += 1
            in_multiline_comment = false
            next
          elsif line =~ patterns[:multiline_end]
            @comments += 1
            in_multiline_comment = false
            next
          end
        end
        
        case line
        when patterns[:multiline_begin]
          in_multiline_comment = true 
          if patterns.include?(:multiline_begin_mixed) and 
            line =~ patterns[:multiline_begin_mixed]
            @code += 1
          end
          
          if line.sub(patterns[:multiline_begin], "X") =~ patterns[:multiline_end]
            in_multiline_comment = false
          end
          @comments += 1
          
        when patterns[:blank_line]
          @blank += 1
        
        when patterns[:single_line_full]
          @comments += 1
        
        when patterns[:single_line_mixed]
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
      puts data.to_s
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
        puts "Error: " + $!.to_s
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
        puts "Error: " + $!.to_s
      end    
    end

  end

  #
  # Generates LOC metrics for the specified files and sends the results to the console.
  # Supported options:
  # * :recurse - recurse into sub-directories. Default = false.
  # * :csv - write the results to a csv file. Default = false.
  # * :csvFilename - name of csv file to generate. Used with :csv option. Default = countloc.csv
  # * :html - write the results to a html file. Default = false.
  # * :htmlFilename - name of html file to generate. Used with :html option. Default = countloc.html  
  # * :quiet - do not output results to stdout
  # * :mode - language mode. Determines parsing rules and default file types. 
  #   Supported modes: ruby, python, c, cpp, csharp, java, vb.
  #   If no mode is selected, the default mode is to select the parsing rules based on 
  #   file extension. A default set of file extensions covering all supported languages
  #   will be used.
  # * :fileTypes - Types of file to include in the LOC analysis. By default the file types
  #   used are based on the language mode selected. This option can be used to override
  #   the default file types.
  def countloc(files, options = {})
    
    # Setup defaults for filenames
    if options[:defaultMode]
      options[:fileTypes] = DEFAULT_FILE_TYPES.values.flatten if not options[:useUserFileTypes]      
    else
      options[:fileTypes] = DEFAULT_FILE_TYPES[options[:mode]] if not options[:useUserFileTypes]
    end
    
    # Setup the output writers based on the options
    writers = []
    writers << ConsoleWriter.new if not options[:quiet]
    writers << CsvFileWriter.new(options[:csvFilename]) if options[:csv]
    writers << HtmlFileWriter.new(options[:htmlFilename]) if options[:html]

    # Expand directories into the appropriate file lists
    dirs = files.select { |filename| File.directory?(filename) }
    if dirs.size > 0
      recursePattern = ("**" if options[:recurse]) || ""
      files -= dirs
      options[:fileTypes].each do |fileType|
        files += dirs.collect { |dirname| Dir.glob(File.join(dirname, recursePattern, '*'+fileType))}.flatten      
      end
      files.uniq!
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
          mode = options[:mode]
          if options[:defaultMode]
            mode = DEFAULT_STYLE[File.extname(filename)] || options[:mode]
          end
          counter.read(file, mode)
          sum += counter
          results << counter
        end
      rescue
        puts "Error: " + $!.to_s
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
if $0 == __FILE__

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
      options = {}
      options[:recurse] = false
      options[:quiet] = false
      options[:mode] = :ruby
      options[:defaultMode] = true
      options[:csv] = false
      options[:csvFilename] = 'countloc.csv'
      options[:html] = false
      options[:htmlFilename] = 'countloc.html'
      options[:useUserFileTypes] = false
      
      begin
        OptionParser.new do |opts|
          opts.banner = usage

          opts.on('-r', '--recurse', 'Recurse into subdirectories') do
            options[:recurse] = true
          end

          opts.on('-v', '--version', 'Display version number') do 
            puts "#{File.basename($0)}, version: #{CountLOC::VERSION}"
            exit
          end

          opts.on('-q', '--quiet', "Don't write results to stdout") do 
            options[:quiet] = true
          end

          opts.on('-m', '--mode mode', 
            [:ruby, :python, :c, :cpp, :csharp, :java, :vb], 
            "Set the language mode.", 
            "All languages are used by default",
            "if the mode option is omitted.",
            "Supported modes: ",
            "  ruby, python,", 
            "  c, cpp, csharp,", 
            " java, vb") do |mode|
            options[:mode] = mode
            options[:defaultMode] = false
          end

          opts.on('--csv csvFilename', 'Generate csv file') do |csvFilename|
            options[:csvFilename] = csvFilename
            options[:csv] = true
          end

          opts.on('--html htmlFilename', 'Generate html file') do |htmlFilename|
            options[:htmlFilename] = htmlFilename
            options[:html] = true
          end

          opts.on('--file-types fileTypes', 
            "File types to be included.",
            "Default is dependant upon language mode:",
            "  ruby: *.rb",
            "  python: *.py",
            "  c: *.h, *.c",
            "  cpp: *.h, *.hpp, *.cpp, *.c, *.inl",
            "  csharp: *.cs",
            "  java: *.java",
            "  vb: *.vb",
            "Defaults are overridden using this option.") do |fileTypes|
            options[:fileTypes] = fileTypes.split()
            options[:useUserFileTypes] = true
          end

          opts.on_tail('-h', '--help', 'Display this help and exit') do
            puts opts
            exit
          end

        end.parse!(args)

      rescue
        puts "Error: " + $!.to_s
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
