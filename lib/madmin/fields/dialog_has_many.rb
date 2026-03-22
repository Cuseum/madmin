module Madmin
  module Fields
    class DialogHasMany < Field
      def associated_resource
        Madmin.resource_by_name(model.reflect_on_association(attribute_name).klass)
      rescue MissingResource
      end

      def associated_resource_for(object)
        Madmin.resource_for(object)
      rescue MissingResource
      end

      # Returns attributes visible in the index action of the associated resource.
      def index_attributes
        return [] unless associated_resource

        associated_resource.attributes.values.select do |attr|
          attr.field.present? && attr.field.visible?(:index)
        end
      end

      # Builds the edit URL for the associated record, including dialog-mode params.
      def edit_dialog_path(assoc_record)
        ar = associated_resource
        return unless ar

        ar.url_helpers.polymorphic_path(
          [:madmin, ar.route_namespace, ar.becomes(assoc_record)],
          action: :edit,
          dialog: 1,
          frame_id: frame_id
        )
      end

      # Unique HTML id for the <dialog> element for this field.
      def dialog_id
        "madmin-dialog-#{attribute_name}"
      end

      # Unique HTML id for the <turbo-frame> inside the dialog.
      def frame_id
        "madmin-dialog-frame-#{attribute_name}"
      end
    end
  end
end
