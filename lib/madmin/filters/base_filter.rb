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
        self.class.to_s.demodulize.delete_suffix("Filter").underscore.humanize
      end

      # Unique identifier used as the URL param key for this filter.
      # Derived from the fully-qualified class name.
      def id
        self.class.to_s.underscore.tr("/", "_")
      end

      # Returns the value currently applied for this filter, falling back to default.
      def applied_or_default_value(applied_filters)
        applied_value = applied_filters[id]
        applied_value.nil? ? self.class.default : applied_value
      end

      # Override in subclasses to apply the filter to the query.
      # Must return the filtered ActiveRecord relation.
      def apply(query, value)
        raise NotImplementedError, "#{self.class} must implement the `apply` method"
      end

      # Called by the controller to apply this filter.
      # Subclasses should override `apply`, not this method.
      def apply_query(query, value)
        apply(query, value)
      end
    end
  end
end
