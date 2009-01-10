$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

# Copyright (C) 2009  Stephen Doyle

require 'test/unit'
require 'countloc'

class CppTest < Test::Unit::TestCase

  include CountLOC

  def setup
    @counter = LineCounter.new('Test')
    @style = :cplusplus
  end
  
  def test_single_line_comment
    @counter.read("// This is a comment", @style)
    assert_equal(0, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_single_line_comment_with_whitespace
    @counter.read(" // This is a comment", @style)
    assert_equal(0, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_multi_line_comment
    @counter.read(%{/*\nThis is a comment\n*/}, @style)
    assert_equal(0, @counter.code)
    assert_equal(3, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(3, @counter.lines)
  end

  def test_multi_line_comment_on_a_single_line
    @counter.read(%{/*This is a comment*/}, @style)
    assert_equal(0, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_multi_line_comment_with_blank_lines
    @counter.read(%{/* This is a comment\n\n*/}, @style)
    assert_equal(0, @counter.code)
    assert_equal(2, @counter.comments)
    assert_equal(1, @counter.blank)
    assert_equal(3, @counter.lines)
  end

  def test_mixed_with_single_line_comments
    @counter.read("print 'hello' // This is a mixed comment", @style)
    assert_equal(1, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_mixed_with_multi_line_comments
    @counter.read(%{printf("hello"); /* This is a mixed comment */}, @style)
    assert_equal(1, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_single_line_comment_char_in_double_quote_string
    @counter.read(%{printf("//comment");}, @style)
    assert_equal(1, @counter.code)
    assert_equal(0, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_multi_line_comment_char_in_double_quote_string
    @counter.read(%{printf("/* comment */");}, @style)
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
    @counter.read(
      %{/*\n} +
      %{ * Sample foo function\n} +
      %{ */\n} +
      "void foo() {\n" +
      %{    // say hello\n} +
      %{    printf("Hello World");\n} +
      "}\n\n" +
      %{// The End}, @style)
    assert_equal(3, @counter.code)
    assert_equal(5, @counter.comments)
    assert_equal(1, @counter.blank)
    assert_equal(9, @counter.lines)
  end
  
end

