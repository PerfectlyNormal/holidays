module Holidays
  # Get all holidays on a given date.
  #
  # [<tt>date</tt>]     A Date object.
  # [<tt>:options</tt>] One or more region symbols, <tt>:informal</tt> and/or <tt>:observed</tt>.
  #
  # Returns an array of hashes or nil. See Holidays#between for the output
  # format.
  #
  # Also available via Date#holidays.
  def self.on(date, *options)
    self.between(date, date, options)
  end

  # Does the given work-week have any holidays?
  #
  # [<tt>date</tt>]   A Date object.
  # [<tt>:options</tt>] One or more region symbols, and/or <tt>:informal</tt>. Automatically includes <tt>:observed</tt>. If you don't want this, pass <tt>:no_observed</tt>
  #
  # The given Date can be any day of the week.
  # Returns true if any holidays fall on Monday - Friday of the given week.
  def self.full_week?(date, *options)
    days_to_monday = date.wday - 1
    days_to_friday = 5 - date.wday
    start_date = date - days_to_monday
    end_date = date + days_to_friday
    options += [:observed] unless options.include?(:no_observed)
    options.delete(:no_observed)
    self.between(start_date, end_date, options).empty?
  end

  # Get all holidays occuring between two dates, inclusively.
  #
  # Returns an array of Holiday objects or nil.
  #
  # Each holiday is returned as a hash with the following fields:
  # [<tt>start_date</tt>]  Ruby Date object.
  # [<tt>end_date</tt>]    Ruby Date object.
  # [<tt>options</tt>]     One or more region symbols, <tt>:informal</tt> and/or <tt>:observed</tt>.
  #
  # ==== Example
  #   from = Date.civil(2008,7,1)
  #   to   = Date.civil(2008,7,31)
  #
  #   Holidays.between(from, to, :ca, :us)
  #   => [{:name => 'Canada Day', :regions => [:ca]...}
  #       {:name => 'Independence Day'', :regions => [:us], ...}]
  def self.between(start_date, end_date, *options)
    # remove the timezone
    start_date = start_date.new_offset(0) + start_date.offset if start_date.respond_to?(:new_offset)
    end_date = end_date.new_offset(0) + end_date.offset if end_date.respond_to?(:new_offset)

    # get simple dates
    if start_date.respond_to?(:to_date)
      start_date = start_date.to_date
    else
      start_date = Date.civil(start_date.year, start_date.mon, start_date.mday)
    end

    if end_date.respond_to?(:to_date)
      end_date = end_date.to_date
    else
      end_date = Date.civil(end_date.year, end_date.mon, end_date.mday)
    end

    regions, observed, informal = parse_options(options)
    holidays = []

    dates = {}
    (start_date..end_date).each do |date|
      # Always include month '0' for variable-month holidays
      dates[date.year] = [0] unless dates[date.year]
      # TODO: test this, maybe should push then flatten
      dates[date.year] << date.month unless dates[date.year].include?(date.month)
    end

    dates.each do |year, months|
      months.each do |month|
        next unless hbm = @@holidays_by_month[month]

        hbm.each do |h|
          next unless in_region?(regions, h[:regions])

          # Skip informal holidays unless they have been requested
          next if h[:type] == :informal and not informal

          if h[:function]
            # Holiday definition requires a calculation
            result = call_proc(h[:function], year)

            # Procs may return either Date or an integer representing mday
            if result.kind_of?(Date)
              month = result.month
              mday = result.mday
            else
              mday = result
            end
          else
            # Calculate the mday
            mday = h[:mday] || Date.calculate_mday(year, month, h[:week], h[:wday])
          end

          # Silently skip bad mdays
          begin
            date = Date.civil(year, month, mday)
          rescue; next; end

          # If the :observed option is set, calculate the date when the holiday
          # is observed.
          if observed and h[:observed]
            date = call_proc(h[:observed], date)
          end

          if date.between?(start_date, end_date)
            holidays << Holidays::Holiday.new(:date => date, :name => h[:name], :regions => h[:regions])
          end

        end
      end
    end

    holidays.sort{|a, b| a[:date] <=> b[:date] }
  end

  private

  # Returns [(arr)regions, (bool)observed, (bool)informal]
  def self.parse_options(*options) # :nodoc:
    options.flatten!
    observed = options.delete(:observed) ? true : false
    informal = options.delete(:informal) ? true : false
    regions = parse_regions(options)
    return regions, observed, informal
  end

  # Check sub regions.
  #
  # When request :any, all holidays should be returned.
  # When requesting :ca_bc, holidays in :ca or :ca_bc should be returned.
  # When requesting :ca, holidays in :ca but not its subregions should be returned.
  def self.in_region?(requested, available) # :nodoc:
    return true if requested.include?(:any)

    # When an underscore is encountered, derive the parent regions
    # symbol and include both in the requested array.
    requested = requested.collect do |r|
      r.to_s =~ /_/ ? [r, r.to_s.gsub(/_[\w]*$/, '').to_sym] : r
    end

    requested = requested.flatten.uniq

    available.any? { |avail| requested.include?(avail) }
  end
end