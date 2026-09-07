#!/usr/bin/env ruby
# frozen_string_literal: true

# The json gem is loaded before Oj on purpose. Time, Date, Symbol, and the
# other core classes then answer to_json with the json gem's generator, which
# is what Oj.dump calls in compat mode with use_to_json. Kept in its own file
# because loading the json gem changes what every other compat test would
# dump.

$LOAD_PATH << __dir__
@oj_dir = File.dirname(File.expand_path(__dir__))
%w(lib ext).each do |dir|
  $LOAD_PATH << File.join(@oj_dir, dir)
end

require 'minitest'
require 'minitest/autorun'
require 'json'
require 'oj'

class ToJsonJsonGemJuice < Minitest::Test

  def setup
    @default_options = Oj.default_options
    # Set here rather than per call so the hash Oj.dump forwards to to_json
    # holds only the keys under test.
    Oj.default_options = { :mode => :compat, :use_to_json => true }
  end

  def teardown
    Oj.default_options = @default_options
  end

  # The json gem's indent is a String. Oj's Integer indent must reach it as
  # that many spaces.
  def test_dump_time_integer_indent
    t = Time.at(1_355_218_745).utc
    assert_equal('"2012-12-11 09:39:05 UTC"', Oj.dump(t, :indent => 2))
  end

  def test_dump_time_string_indent
    t = Time.at(1_355_218_745).utc
    assert_equal('"2012-12-11 09:39:05 UTC"', Oj.dump(t, :indent => '  '))
  end

  # use_to_json only gates the top level value. Nested values always reach
  # to_json, so a Time inside an Array raised even without the option.
  def test_dump_nested_time_integer_indent_without_use_to_json
    Oj.default_options = { :mode => :compat, :use_to_json => false }
    t = Time.at(1_355_218_745).utc
    json = Oj.dump([t], :indent => 2)
    assert_equal(%|[\n  "2012-12-11 09:39:05 UTC"\n]\n|, json)
  end

  def test_dump_nested_time_integer_indent
    t = Time.at(1_355_218_745).utc
    json = Oj.dump({ 'at' => t }, :indent => 2)
    assert_equal(%|{\n  "at":"2012-12-11 09:39:05 UTC"\n}\n|, json)
  end
end
