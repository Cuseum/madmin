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

      def build(*_args, **kwargs)
        add_class "form-row"
        add_class kwargs[:class] if kwargs[:class]
      end
    end
  end
end
