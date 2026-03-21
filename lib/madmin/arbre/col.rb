module Madmin
  module Arbre
    # Wraps its block content in a `.form-col` container.
    # Use inside a `row` block to define individual columns:
    #
    #   row do
    #     col { attribute :first_name }
    #     col { attribute :last_name }
    #   end
    class Col < ::Arbre::Component
      builder_method :col

      def build(*args, **kwargs)
        add_class "form-col"
        html_options = args.last.is_a?(::Hash) ? args.last.merge(kwargs) : kwargs
        add_class html_options[:class] if html_options[:class]
      end
    end
  end
end
