module Holidays
  # Merge a new set of definitions into the Holidays module.
  #
  # This method is automatically called when including holiday definition
  # files.
  def self.merge_defs(regions, holidays) # :nodoc:
    @@regions = @@regions | regions
    @@regions.uniq!

    holidays.each do |month, holiday_defs|
      @@holidays_by_month[month] = [] unless @@holidays_by_month[month]
      holiday_defs.each do |holiday_def|

          exists = false
          @@holidays_by_month[month].each do |ex|
            # TODO: gross.
            if ex[:name] == holiday_def[:name] and ex[:wday] == holiday_def[:wday] and ex[:mday] == holiday_def[:mday] and ex[:week] == holiday_def[:week] and ex[:function_id] == holiday_def[:function_id] and ex[:type] == holiday_def[:type] and ex[:observed_id] == holiday_def[:observed_id]
              # append regions
              ex[:regions] << holiday_def[:regions]

              # Should do this once we're done
              ex[:regions].flatten!
              ex[:regions].uniq!
              exists = true
            end
          end

          @@holidays_by_month[month] << holiday_def  unless exists
      end
    end
  end

  # Returns an array of symbols all the available holiday definitions.
  #
  # Optional `full_path` param is used internally for loading all the definitions.
  def self.available(full_path = false)
    paths = Dir.glob(DEFINITION_PATH + '/*.rb')
    full_path ? paths : paths.collect { |path| path.match(/([a-z_-]+)\.rb/i)[1].to_sym }
  end

  # Load all available holiday definitions
  def self.load_all
    self.available(true).each { |path| require path }
  end

  private

  # Check regions against list of supported regions and return an array of
  # symbols.
  #
  # If a wildcard region is found (e.g. <tt>:ca_</tt>) it is expanded into all
  # of its available sub regions.
  def self.parse_regions(regions) # :nodoc:
    regions = [regions] unless regions.kind_of?(Array)
    return [:any] if regions.empty?

    regions = regions.collect { |r| r.to_sym }

    # Found sub region wild-card
    regions.delete_if do |reg|
      if reg.to_s =~ /_$/
        prefix = reg.to_s.split('_').first
        raise UnknownRegionError unless @@regions.include?(prefix.to_sym) or begin require "holidays/regions/#{prefix}"; rescue LoadError; false; end
        regions << @@regions.select { |dr| dr.to_s =~ Regexp.new("^#{reg}") }
        true
      end
    end

    regions.flatten!

    require "holidays/regions/north_america" if regions.include?(:us) # special case for north_america/US cross-linking

    raise UnknownRegionError unless regions.all? { |r| r == :any or @@regions.include?(r) or begin require "holidays/regions/#{r.to_s}"; rescue LoadError; false; end }
    regions
  end
end