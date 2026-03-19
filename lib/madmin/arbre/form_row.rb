module Madmin
  module Arbre
    # Renders a form row layout wrapper around a set of FormCol components.
    # Corresponds to the `row` DSL method used in Madmin resource form blocks.
    # Sets the CSS custom property `--madmin-cols` to drive the grid column count.
    class FormRow < ::Arbre::Component
      builder_method :madmin_form_row

      def build(form_row, locals = {})
        add_class "form-row"
        set_attribute :style, "--madmin-cols: #{form_row.cols.size}"

        form_row.cols.each do |form_col|
          madmin_form_col(form_col, locals)
        end
      end
    end
  end
end
