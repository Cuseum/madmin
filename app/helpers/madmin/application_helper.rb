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
    def render_arbre(block, assigns = {})
      Arbre::Context.new(assigns, self, &block).to_s.html_safe
    end
  end
end
