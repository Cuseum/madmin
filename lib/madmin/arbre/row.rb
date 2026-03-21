module Madmin
  module Arbre
    # Wraps its block content in a `.form-row` grid container.
    # Use inside Arbre-based form blocks to create multi-column layouts:
    #
    #   row do
    #     col { attribute :first_name }
    #     col { attribute :last_name }
    #   end
    class Row < ::Arbre::Component
      builder_method :row

      def build(*args, **kwargs)
        add_class "form-row"
        html_options = args.last.is_a?(::Hash) ? args.last.merge(kwargs) : kwargs
        add_class html_options[:class] if html_options[:class]
      end
    end
  end
end
