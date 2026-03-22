module Madmin
  module Filters
    class TextFilter < BaseFilter
      class << self
        def filter_type
          "text_filter"
        end
      end
    end
  end
end
