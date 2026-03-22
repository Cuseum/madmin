module Madmin
  class ResourceController < Madmin::ApplicationController
    include SortHelper

    before_action :set_record, except: [:index, :new, :create]

    # Assign current_user for paper_trail gem
    before_action :set_paper_trail_whodunnit, if: -> { respond_to?(:set_paper_trail_whodunnit, true) }

    def index
      @pagy, @records = pagy(scoped_resources)

      respond_to do |format|
        format.html
        format.json {
          render json: @records.map { |r| {name: @resource.display_name(r), id: r.id} }
        }
      end
    end

    def show
    end

    def new
      @record = resource.model.new(new_resource_params)
    end

    def create
      @record = resource.model.new(resource_params)
      if @record.save
        redirect_to resource.show_path(@record)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @record.update(resource_params)
        tab = params[:tab].presence
        if tab && resource.form_tab_for(tab)
          redirect_to resource.tab_edit_path(@record, tab)
        else
          redirect_to resource.show_path(@record)
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @record.destroy
      redirect_to resource.index_path
    end

    private

    def set_record
      @record = resource.model_find(params[:id])
    end

    def resource
      @resource ||= resource_name.constantize
    end
    helper_method :resource

    def resource_name
      "#{controller_path.singularize}_resource".delete_prefix("madmin/").classify
    end

    def scoped_resources
      resources = resource.model.send(valid_scope)
      resources = apply_filters(resources)
      resources = Madmin::Search.new(resources, resource, search_term).run
      resources.reorder(sort_column => sort_direction)
    end

    def valid_scope
      scope = params.fetch(:scope, "all")
      resource.scopes.include?(scope.to_sym) ? scope : :all
    end

    def apply_filters(query)
      return query if resource.filters.empty? || params[:filters].blank?

      filter_instances = resource.filters.map(&:new)
      applied_filters = build_applied_filters(filter_instances)
      filter_instances.each do |filter|
        value = filter.applied_or_default_value(applied_filters)
        query = filter.apply_query(query, value) if value.present?
      end
      query
    end

    # Builds a hash of { filter_id => { comparator => [values] } } from
    # the nested params format: filters[filter_id][comparator][]=value
    # Only accesses params for registered filter IDs; permits the inner hash
    # of each known filter to avoid unpermitted-parameter warnings.
    def build_applied_filters(filter_instances)
      filter_instances.each_with_object({}) do |filter, result|
        raw = params[:filters]&.dig(filter.id)
        next if raw.blank?

        # raw is ActionController::Parameters like { "is" => ["active"] }.
        # Permit it fully since it's already scoped to a developer-registered filter ID
        # and the filter's apply method controls how values are used.
        result[filter.id] = raw.permit!.to_h.transform_values { |v| Array(v) }
      end
    end

    def resource_params
      tab = params[:tab].presence
      permitted = if tab && resource.form_tab_for(tab)
        resource.tab_permitted_params(tab)
      else
        resource.permitted_params
      end
      params.require(resource.param_key)
        .permit(*permitted)
        .transform_values { |v| change_polymorphic(v) }
    end

    def new_resource_params
      params.fetch(resource.param_key, {}).permit!
        .permit(*resource.permitted_params)
        .transform_values { |v| change_polymorphic(v) }
    end

    def change_polymorphic(data)
      return data unless data.is_a?(ActionController::Parameters) && data[:type]

      if data[:type] == "polymorphic"
        GlobalID::Locator.locate(data[:value])
      else
        raise "Unrecognised param data: #{data.inspect}"
      end
    end

    def search_term
      @search_term ||= params[:q].to_s.strip
    end
  end
end
