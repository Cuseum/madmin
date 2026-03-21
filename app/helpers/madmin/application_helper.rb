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
    # When `assigns` contains `:resource`, `:form`, and `:record`, an `attribute`
    # method is injected into the Arbre context so that calls like
    # `col { attribute :first_name }` render the corresponding form field partial
    # at Arbre render time.
    def render_arbre(block, assigns = {})
      resource = assigns[:resource]
      form = assigns[:form]
      record = assigns[:record]
      view = self

      ctx = ::Arbre::Context.new(assigns, self)

      # Make `attribute` callable inside Arbre blocks so that field-rendering
      # calls like `col { attribute :first_name }` work. The block is yielded
      # by Arbre's builder mechanism with `self` = context and `current_arbre_element`
      # pointing at the enclosing component (e.g. the Col div), so the rendered
      # field HTML is appended to the correct place in the tree.
      ctx.define_singleton_method(:attribute) do |attr_name, *_args, **_opts|
        next unless resource
        attr = resource.attributes[attr_name]
        next unless attr&.field&.present?
        current_arbre_element << view.render(
          "madmin/shared/form_field",
          field: attr.field,
          record: record,
          form: form,
          resource: resource
        )
      end

      # Override Arbre's built-in <section> HTML element builder so that the
      # Madmin section DSL (with label: and description: kwargs) works correctly
      # inside Arbre form blocks.  The section body is rendered via the shared
      # _form_section partial so that both Arbre and non-Arbre form paths produce
      # identical markup from a single source of truth.
      ctx.define_singleton_method(:section) do |section_name, label: section_name.to_s.humanize, description: nil, &block|
        body_html = block ? view.render_arbre(block, assigns) : "".html_safe
        current_arbre_element << view.render(
          partial: "madmin/application/form_section",
          locals: { label: label, description: description, content: body_html }
        )
      end

      ctx.instance_exec(&block)
      ctx.to_s.html_safe
    end
  end
end
