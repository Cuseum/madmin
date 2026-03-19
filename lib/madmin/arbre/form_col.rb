module Madmin
  module Arbre
    # Renders a single column within a form row, outputting each attribute's
    # form field partial via the Rails view helpers.
    # Corresponds to the `col` DSL method used in Madmin resource form blocks.
    class FormCol < ::Arbre::Component
      builder_method :madmin_form_col

      def build(form_col, locals = {})
        add_class "form-col"

        form = locals[:form]
        record = locals[:record]
        resource = locals[:resource]
        action_name = locals[:action_name]

        form_col.attribute_names.each do |attr_name|
          attribute = resource.attributes[attr_name]
          next if attribute.nil? || attribute.field.nil? || !attribute.field.visible?(action_name)

          self << helpers.render(
            "madmin/shared/form_field",
            field: attribute.field,
            record: record,
            form: form,
            resource: resource
          )
        end
      end
    end
  end
end
