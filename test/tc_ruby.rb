$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

# Copyright (C) 2008  Stephen Doyle

require 'test/unit'
require 'countloc'

class RubyTest < Test::Unit::TestCase
  
  def test_ruby_single_line_comments
    stats = countloc('ruby_single_line_comments.rb')
    assert_equal(14, stats['code'])
    assert_equal(6, stats['comments'])
    assert_equal(5, stats['blank'])
    assert_equal(23, stats['total'])
  end

  def test_ruby_multi_line_comments
    stats = countloc('ruby_multiline_comments.rb')
    assert_equal(2, stats['code'])
    assert_equal(4, stats['comments'])
    assert_equal(1, stats['blank'])
    assert_equal(7, stats['total'])
  end

end


