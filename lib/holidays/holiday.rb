module Holidays
  class Holiday
    attr_reader :name, :date, :regions

    def initialize(options = {})
      @date    = options[:date]
      @name    = options[:name]
      @regions = options[:regions]
    end

    # Backwards compatibility with the hashes
    def [](key)
      case key
      when :name       then name
      when :date       then date
      when :regions    then regions
      else nil
      end
    end

    def <=>(other)
      date <=> other.date
    end
  end
end