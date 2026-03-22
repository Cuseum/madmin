module Madmin
  module Filters
    class MultipleSelectFilter < BaseFilter
      class << self
        def filter_type
          "multiple_select_filter"
        end
      end
    end
  end
end
