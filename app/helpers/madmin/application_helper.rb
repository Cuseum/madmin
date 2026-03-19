module Madmin
  module ApplicationHelper
    include Pagy::Frontend if defined? Pagy::Frontend
    include Rails.application.routes.url_helpers

    def clear_search_params
      resource.index_path(sort: params[:sort], direction: params[:direction])
    end

    # Renders an arbre block proc using Arbre::Context and returns the HTML output.
    # Arbre escapes string content by default (similar to ERB), so user-provided
    # data interpolated in blocks will be HTML-escaped unless explicitly marked
    # safe. Developers are responsible for using html_safe or raw only on trusted
    # content, as with any other Rails view helper.
    #
    # When `assigns` contains `:resource`, `:form`, `:record`, and `:action_name`,
    # an `attribute` method is injected into the Arbre context so that calls like
    # `col { attribute :first_name }` render the corresponding form field partial
    # at Arbre render time.
    def render_arbre(block, assigns = {})
      resource = assigns[:resource]
      form = assigns[:form]
      record = assigns[:record]
      view_action = assigns.fetch(:action_name) { action_name }.to_s
      view = self

      ctx = ::Arbre::Context.new(assigns, self)

      # Make `attribute` callable inside Arbre blocks so that field-rendering
      # calls like `col { attribute :first_name }` work. The block is yielded
      # by Arbre's builder mechanism with `self` = context and `current_arbre_element`
      # pointing at the enclosing component (e.g. the Col div), so the rendered
      # field HTML is appended to the correct place in the tree.
      ctx.define_singleton_method(:attribute) do |attr_name, **_opts|
        next unless resource
        attr = resource.attributes[attr_name]
        next unless attr&.field&.present? && attr.field.visible?(view_action)
        current_arbre_element << view.render(
          "madmin/shared/form_field",
          field: attr.field,
          record: record,
          form: form,
          resource: resource
        )
      end

      ctx.instance_exec(&block)
      ctx.to_s.html_safe
    end
  end
end
