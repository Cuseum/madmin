module Madmin
  module Filters
    class BaseFilter
      class_attribute :default, default: nil
      # Controls whether the filter is shown in the UI.
      # Set to a callable (proc/lambda) that returns true/false, or a plain boolean.
      # Nil means always visible.
      class_attribute :visible

      # The display name shown in the UI.
      # Defaults to the class name with "Filter" suffix removed and humanized.
      # Override in subclasses to provide a custom label.
      def name
        base_key.humanize
      end

      # Unique identifier used as the URL param key for this filter.
      # Derived from the demodulized class name with the "Filter" suffix removed.
      # e.g. StatusFilter → "status", MyApp::PublishedFilter → "published"
      def id
        base_key
      end

      # Returns the value currently applied for this filter, falling back to default.
      def applied_or_default_value(applied_filters)
        applied_value = applied_filters[id]
        applied_value.nil? ? self.class.default : applied_value
      end

      # Override in subclasses to apply the filter to the query.
      # Must return the filtered ActiveRecord relation.
      #
      # When called from the controller, `value` is a hash of the form:
      #   { "is" => ["active", "pending"], "gt" => ["100"] }
      # Each key is a comparator string, and each value is an array of strings.
      # Use the `values_for` helper to extract values for a specific comparator.
      def apply(query, value)
        raise NotImplementedError, "#{self.class} must implement the `apply` method"
      end

      # Called by the controller to apply this filter.
      # Subclasses should override `apply`, not this method.
      def apply_query(query, value)
        apply(query, value)
      end

      # Extracts the array of values for the given comparator from `value`.
      # Accepts both symbol and string comparator keys.
      #
      # Example:
      #   value = { "is" => ["active", "pending"], "is_not" => ["archived"] }
      #   values_for(value, :is)     # => ["active", "pending"]
      #   values_for(value, :is_not) # => ["archived"]
      #   values_for(value, :gt)     # => []
      def values_for(value, comparator)
        return [] unless value.is_a?(Hash)
        key = comparator.to_s
        Array(value.fetch(key) { value[comparator.to_sym] })
      end

      private

      # Shared base used by both `name` and `id`.
      # Strips the namespace and "Filter" suffix, then underscores.
      def base_key
        self.class.to_s.demodulize.delete_suffix("Filter").underscore
      end
    end
  end
end
