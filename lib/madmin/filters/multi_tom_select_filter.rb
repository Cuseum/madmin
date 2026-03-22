module Madmin
  module Filters
    class MultiTomSelectFilter < BaseFilter
      # Optional URL for dynamic AJAX-based option loading.
      # The endpoint must return JSON in the format:
      #   [{ "id": "1", "name": "Alice" }, ...]
      # Accepts an optional `q` query parameter for search.
      # If nil, the filter falls back to static `options`.
      class_attribute :url, default: nil

      def self.filter_type
        "multi_tom_select_filter"
      end
    end
  end
end
