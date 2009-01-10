$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

# Copyright (C) 2008  Stephen Doyle

require 'test/unit'
require 'countloc'

class RubyTest < Test::Unit::TestCase

  include CountLOC

  def setup
    @counter = LineCounter.new('Test')
    @style = :ruby
  end
  
  def test_single_line_comment
    @counter.read("# This is a comment", @style)
    assert_equal(0, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_single_line_comment_with_whitespace
    @counter.read("  # This is a comment", @style)
    assert_equal(0, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_multi_line_comment
    @counter.read("=begin\n# This is a comment\n=end", @style)
    assert_equal(0, @counter.code)
    assert_equal(3, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(3, @counter.lines)
  end

  def test_multi_line_comment_with_blank_lines
    @counter.read("=begin\n# This is a comment\n\n=end", @style)
    assert_equal(0, @counter.code)
    assert_equal(3, @counter.comments)
    assert_equal(1, @counter.blank)
    assert_equal(4, @counter.lines)
  end

  def test_mixed
    @counter.read("puts 'hello' # This is a mixed comment", @style)
    assert_equal(1, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_comment_char_in_double_quote_string
    @counter.read('puts "hello #"', @style)
    assert_equal(1, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_comment_char_in_single_quote_string
    @counter.read("puts 'hello #'", @style)
    assert_equal(1, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_comment_char_in_regexp
    @counter.read("puts /#/", @style)
    assert_equal(1, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_blank_lines_with_newline
    @counter.read("\n", @style)
    assert_equal(0, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(1, @counter.blank)
    assert_equal(1, @counter.lines)
  end
  
  def test_blank_lines_with_whitespace
    @counter.read("    \t", @style)
    assert_equal(0, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(1, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_mixed_code_and_comments
    @counter.read("# This is a comment\n" +
      "1.upto(5).each {|x| puts x}\n" +
      "=begin\n" +
      " multiline comment\n" +
      "=end\n" +
      "puts 'blah'", @style)
    assert_equal(2, @counter.code)
    assert_equal(4, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(6, @counter.lines)
  end

end


