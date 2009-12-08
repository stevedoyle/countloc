$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

# Copyright (C) 2008  Stephen Doyle

require 'test/unit'
require 'countloc'

class VBTest < Test::Unit::TestCase

  include CountLOC

  def setup
    @counter = LineCounter.new('Test')
    @style = :vb
  end
  
  def test_single_line_comment
    @counter.read("' This is a comment", @style)
    assert_equal(0, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_single_line_comment_with_whitespace
    @counter.read("  ' This is a comment", @style)
    assert_equal(0, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_mixed
    @counter.read("Label1.Visible = false ' This is a mixed comment", @style)
    assert_equal(1, @counter.code)
    assert_equal(1, @counter.comments)
    assert_equal(0, @counter.blank)
    assert_equal(1, @counter.lines)
  end

  def test_comment_char_in_double_quote_string
    @counter.read("x = \"hello '\"", @style)
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

end


