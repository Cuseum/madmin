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

      def build(*_args, **_kwargs, &block)
        div(class: "form-row", &block)
      end
    end
  end
end
