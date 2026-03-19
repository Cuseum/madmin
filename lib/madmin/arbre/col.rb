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

      def build(*_args, **_kwargs)
        add_class "form-col"
      end
    end
  end
end
