# encoding: utf-8
$:.unshift File.dirname(__FILE__)

require 'digest/md5'
require 'date'
require 'holidays/loader'
require 'holidays/lookup'
require 'holidays/calculations'
require 'holidays/holiday'
require 'holidays/core_ext/date'

if defined?(Rails)
  require 'holidays/rails'
  Holidays::Holiday.send :include, Holidays::Holiday::Rails
end

# == Region options
# Holidays can be defined as belonging to one or more regions and sub regions.
# The Holidays#on, Holidays#between, Date#holidays and Date#holiday? methods
# each allow you to specify a specific region.
#
# There are several different ways that you can specify a region:
#
# [<tt>:region</tt>]
#   By region. For example, return holidays in the Canada with <tt>:ca</tt>.
# [<tt>:region_</tt>]
#   By region and sub regions. For example, return holidays in Germany
#   and all its sub regions with <tt>:de_</tt>.
# [<tt>:region_sub</tt>]
#   By sub region. Return national holidays in Spain plus holidays in Spain's
#   Valencia region with <tt>:es_v</tt>.
# [<tt>:any</tt>]
#   Any region.  Return holidays from any loaded region.
#
#
# You can load all the available holiday definition sets by running
#   Holidays.load_all
# == Other options
# [<tt>:observed</tt>]    Return holidays on the day they are observed (e.g. on a Monday if they fall on a Sunday).
# [<tt>:informal</tt>]    Include informal holidays (e.g. Valentine's Day)
#
# == Examples
# Return all holidays in the <tt>:ca</tt> and <tt>:us</tt> regions on the day that they are
# observed.
#
#   Holidays.between(from, to, :ca, :us, :observed)
#
# Return all holidays in <tt>:ca</tt> and any <tt>:ca</tt> sub-region.
#
#   Holidays.between(from, to, :ca_)
#
# Return all holidays in <tt>:ca_bc</tt> sub-region (which includes the <tt>:ca</tt>), including informal holidays.
#
#   Holidays.between(from, to, :ca_bc, :informal)
module Holidays
  # Exception thrown when an unknown region is requested.
  class UnknownRegionError < ArgumentError; end

  VERSION = '1.0.5'

  @@regions = []
  @@holidays_by_month = {}
  @@proc_cache = {}

  WEEKS = {:first       => 1,
           :second      => 2,
           :third       => 3,
           :fourth      => 4,
           :fifth       => 5,
           :last        => -1,
           :second_last => -2,
           :third_last  => -3}
  MONTH_LENGTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  DAY_SYMBOLS = Date::DAYNAMES.collect { |n| n.downcase.intern }
  DEFINITION_PATH = File.expand_path(File.dirname(__FILE__) + '/holidays/regions/')

  # Call a proc function defined in a holiday definition file.
  #
  # Procs are cached.
  #
  # ==== Benchmarks
  #
  # Lookup Easter Sunday, with caching, by number of iterations:
  #
  #       user     system      total        real
  # 0001  0.000000   0.000000   0.000000 (  0.000000)
  # 0010  0.000000   0.000000   0.000000 (  0.000000)
  # 0100  0.078000   0.000000   0.078000 (  0.078000)
  # 1000  0.641000   0.000000   0.641000 (  0.641000)
  # 5000  3.172000   0.015000   3.187000 (  3.219000)
  #
  # Lookup Easter Sunday, without caching, by number of iterations:
  #
  #       user     system      total        real
  # 0001  0.000000   0.000000   0.000000 (  0.000000)
  # 0010  0.016000   0.000000   0.016000 (  0.016000)
  # 0100  0.125000   0.000000   0.125000 (  0.125000)
  # 1000  1.234000   0.000000   1.234000 (  1.234000)
  # 5000  6.094000   0.031000   6.125000 (  6.141000)
  def self.call_proc(function, year) # :nodoc:
    proc_key = Digest::MD5.hexdigest("#{function.to_s}_#{year.to_s}")
    @@proc_cache[proc_key] = function.call(year) unless @@proc_cache[proc_key]
    @@proc_cache[proc_key]
  end
end