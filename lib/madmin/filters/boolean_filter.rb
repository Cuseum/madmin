module Madmin
  module Filters
    class BooleanFilter < BaseFilter
      class << self
        def filter_type
          "boolean_filter"
        end
      end
    end
  end
end
