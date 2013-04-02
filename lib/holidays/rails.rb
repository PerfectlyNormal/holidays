module Holidays
  class Holiday
    module Rails
      extend ActiveSupport::Concern

      module ClassMethods
        def model_name
          ActiveModel::Name.new(Holidays::Holiday)
        end
      end

      def to_key
        [parameterize(name)]
      end

      def param_key
        "holiday"
      end

      private

      def parameterize(string)
        sep = '-'

        # replace accented chars with their ascii equivalents
        parameterized_string = transliterate(string)
        # Turn unwanted chars into the separator
        parameterized_string.gsub!(/[^a-z0-9\-_]+/, sep)
        unless sep.nil? || sep.empty?
          re_sep = Regexp.escape(sep)
          # No more than one of the separator in a row.
          parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
          # Remove leading/trailing separator.
          parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/, '')
        end
        parameterized_string.downcase
      end

      def transliterate(string)
        I18n.transliterate(ActiveSupport::Multibyte::Unicode.normalize(
          ActiveSupport::Multibyte::Unicode.tidy_bytes(string), :c),
            :replacement => "?")
      end
    end
  end
end