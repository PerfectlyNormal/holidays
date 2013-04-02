# === Extending Ruby's Date class with the Holidays gem
# The Holidays gem automatically extends Ruby's Date class and gives you access
# to three new methods: holiday?, #holidays and #calculate_mday.
#
# ==== Examples
# Lookup Canada Day in the <tt>:ca</tt> region
#   Date.civil(2008,7,1).holiday?(:ca)
#   => true
#
# Lookup Canada Day in the <tt>:fr</tt> region
#   Date.civil(2008,7,1).holiday?(:fr)
#   => false
#
# Lookup holidays on North America in January 1.
#   Date.civil(2008,1,1).holidays(:ca, :mx, :us, :informal, :observed)
#   => [{:name => 'New Year\'s Day'...}]
class Date
  include Holidays

  # Get holidays on the current date.
  #
  # Returns an array of hashes or nil. See Holidays#between for options
  # and the output format.
  #
  #   Date.civil('2008-01-01').holidays(:ca_)
  #   => [{:name => 'New Year\'s Day',...}]
  #
  # Also available via Holidays#on.
  def holidays(*options)
    Holidays.on(self, options)
  end

  # Check if the current date is a holiday.
  #
  # Returns true or false.
  #
  #   Date.civil('2008-01-01').holiday?(:ca)
  #   => true
  def holiday?(*options)
    holidays = self.holidays(options)
    holidays && !holidays.empty?
  end

  # Calculate day of the month based on the week number and the day of the
  # week.
  #
  # ==== Parameters
  # [<tt>year</tt>]  Integer.
  # [<tt>month</tt>] Integer from 1-12.
  # [<tt>week</tt>]  One of <tt>:first</tt>, <tt>:second</tt>, <tt>:third</tt>,
  #                  <tt>:fourth</tt>, <tt>:fifth</tt> or <tt>:last</tt>.
  # [<tt>wday</tt>]  Day of the week as an integer from 0 (Sunday) to 6
  #                  (Saturday) or as a symbol (e.g. <tt>:monday</tt>).
  #
  # Returns an integer.
  #
  # ===== Examples
  # First Monday of January, 2008:
  #   Date.calculate_mday(2008, 1, :first, :monday)
  #   => 7
  #
  # Third Thursday of December, 2008:
  #   Date.calculate_mday(2008, 12, :third, :thursday)
  #   => 18
  #
  # Last Monday of January, 2008:
  #   Date.calculate_mday(2008, 1, :last, 1)
  #   => 28
  #--
  # see http://www.irt.org/articles/js050/index.htm
  def self.calculate_mday(year, month, week, wday)
    raise ArgumentError, "Week parameter must be one of Holidays::WEEKS (provided #{week})." unless WEEKS.include?(week) or WEEKS.has_value?(week)

    unless wday.kind_of?(Numeric) and wday.between?(0,6) or DAY_SYMBOLS.index(wday)
      raise ArgumentError, "Wday parameter must be an integer between 0 and 6 or one of Date::DAY_SYMBOLS."
    end

    week = WEEKS[week] if week.kind_of?(Symbol)
    wday = DAY_SYMBOLS.index(wday) if wday.kind_of?(Symbol)

    # :first, :second, :third, :fourth or :fifth
    if week > 0
      return ((week - 1) * 7) + 1 + ((wday - Date.civil(year, month,(week-1)*7 + 1).wday) % 7)
    end

    days = MONTH_LENGTHS[month-1]

    days = 29 if month == 2 and Date.leap?(year)

    return days - ((Date.civil(year, month, days).wday - wday + 7) % 7) - (7 * (week.abs - 1))
  end
end