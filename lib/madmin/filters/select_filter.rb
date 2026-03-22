module Madmin
  module Filters
    class SelectFilter < BaseFilter
      class << self
        def filter_type
          "select_filter"
        end
      end
    end
  end
end
