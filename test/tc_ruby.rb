$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

# Copyright (C) 2008  Stephen Doyle

require 'test/unit'
require 'countloc'

class RubyTest < Test::Unit::TestCase

  include CountLOC

  def setup
    @counter = LineCounter.new('Test')
  end
  
  def test_ruby_single_line_comment
    @counter.read("# This is a comment")
    assert_equal(0, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_ruby_single_line_comment_with_whitespace
    @counter.read("  # This is a comment")
    assert_equal(0, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_ruby_multi_line_comment
    @counter.read("=begin\n# This is a comment\n=end")
    assert_equal(0, @counter.code)
    assert_equal(3, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(3, @counter.lines)
  end

  def test_ruby_multi_line_comment_with_blank_lines
    @counter.read("=begin\n# This is a comment\n\n=end")
    assert_equal(0, @counter.code)
    assert_equal(3, @counter.comments)
    assert_equal(1, @counter.blank)
    assert_equal(4, @counter.lines)
  end

  def test_ruby_mixed
    @counter.read("puts 'hello' # This is a mixed comment")
    assert_equal(1, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_ruby_comment_char_in_double_quote_string
    @counter.read('puts "hello #"')
    assert_equal(1, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_ruby_comment_char_in_single_quote_string
    @counter.read("puts 'hello #'")
    assert_equal(1, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_ruby_comment_char_in_regexp
    @counter.read("puts /#/")
    assert_equal(1, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_ruby_blank_lines_with_newline
    @counter.read("\n")
    assert_equal(0, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(1, @counter.blank)
    assert_equal(1, @counter.lines)
  end
  
  def test_ruby_blank_lines_with_whitespace
    @counter.read("    \t")
    assert_equal(0, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(1, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_ruby_mixed_code_and_comments
    @counter.read("# This is a comment\n" +
      "1.upto(5).each {|x| puts x}\n" +
      "=begin\n" +
      " multiline comment\n" +
      "=end")
    assert_equal(1, @counter.code)
    assert_equal(4, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(5, @counter.lines)
  end

end


