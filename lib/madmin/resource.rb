module Madmin
  class Resource
    Attribute = Data.define(:name, :type, :field)
    FormTab = Data.define(:name, :label, :attribute_names, :tab_items, :tab_block)
    FormSection = Data.define(:name, :label, :description, :section_items) do
      # section_items is always an array of attribute name symbols; row/col
      # nesting is handled by Arbre at render time, not by this data struct.
      def attribute_names
        section_items
      end
    end

    # A proxy object used when evaluating index/show/form blocks at class definition
    # time. It delegates known DSL methods (attribute, section) to the resource
    # class and silently captures any arbre-style HTML element calls (h1, p, div,
    # row, col, etc.) so they can be rendered later via Arbre::Context.
    class BlockProxy
      def initialize(resource_class)
        @resource_class = resource_class
        @uses_arbre = false
      end

      def uses_arbre?
        @uses_arbre
      end

      def attribute(...)
        @resource_class.attribute(...)
      end

      def section(...)
        @resource_class.section(...)
      end

      # `row` and `col` are Arbre component builder methods (Madmin::Arbre::Row /
      # Madmin::Arbre::Col). Mark the block as Arbre-based and still execute the
      # nested block in this proxy's context so any `attribute` calls inside
      # register field visibility on the resource before Arbre::Context renders
      # the block at request time.
      def row(*_args, **_kwargs, &block)
        @uses_arbre = true
        instance_exec(&block) if block
      end

      def col(*_args, **_kwargs, &block)
        @uses_arbre = true
        instance_exec(&block) if block
      end

      # Arbre uses `para` as the builder method for `<p>` elements to avoid
      # conflict with Ruby's Kernel#p. Explicitly define `p` here so it is
      # detected as an arbre call rather than dispatching to Kernel#p. Like
      # method_missing below, this only sets the detection flag; actual rendering
      # happens later via Arbre::Context in views.
      def p(*_args, **_kwargs, &_block)
        @uses_arbre = true
      end

      # Intentionally intercepts all unknown method calls (arbre HTML elements like
      # h1, div, etc.) without calling super. The BlockProxy is a purpose-built
      # proxy whose entire job is to detect and silently absorb arbre-style calls
      # during class definition time so the raw block can later be rendered by
      # Arbre::Context in views. Calling super here would raise NoMethodError, which
      # is undesirable.
      def method_missing(_method_name, *_args, **_kwargs)
        @uses_arbre = true
      end

      def respond_to_missing?(_method_name, _include_private = false)
        true
      end
    end

    class_attribute :attributes, default: ActiveSupport::OrderedHash.new
    class_attribute :member_actions, default: []
    class_attribute :filters, default: []
    class_attribute :scopes, default: []
    class_attribute :menu_options, instance_reader: false
    class_attribute :index_attributes, default: nil
    class_attribute :show_attributes, default: nil
    class_attribute :form_attributes, default: nil
    class_attribute :form_tabs, default: []
    class_attribute :form_sections, default: []
    class_attribute :form_items, default: []
    class_attribute :index_block, default: nil
    class_attribute :show_block, default: nil
    class_attribute :form_block, default: nil

    class << self
      def inherited(base)
        base.attributes = attributes.dup
        base.member_actions = member_actions.dup
        base.filters = []
        base.scopes = scopes.dup
        base.form_tabs = []
        base.form_sections = []
        base.form_items = []
        base.index_block = nil
        base.show_block = nil
        base.form_block = nil
        super
      end

      def index(&block)
        self.index_attributes = []
        self.index_block = nil
        Thread.current[:madmin_collecting_for] = [:index, self, nil]
        proxy = BlockProxy.new(self)
        proxy.instance_exec(&block)
        self.index_block = block if proxy.uses_arbre?
      ensure
        Thread.current[:madmin_collecting_for] = nil
      end

      def show(&block)
        self.show_attributes = []
        self.show_block = nil
        Thread.current[:madmin_collecting_for] = [:show, self, nil]
        proxy = BlockProxy.new(self)
        proxy.instance_exec(&block)
        self.show_block = block if proxy.uses_arbre?
      ensure
        Thread.current[:madmin_collecting_for] = nil
      end

      def form(&block)
        self.form_attributes = []
        self.form_items = []
        self.form_block = nil
        Thread.current[:madmin_collecting_for] = [:form, self, nil]
        proxy = BlockProxy.new(self)
        proxy.instance_exec(&block)
        self.form_block = block if proxy.uses_arbre?
      ensure
        Thread.current[:madmin_collecting_for] = nil
      end

      def section(name, label: name.to_s.humanize, description: nil, &block)
        previous_context = Thread.current[:madmin_collecting_for]
        section_items = []
        Thread.current[:madmin_collecting_for] = [:form_section, self, section_items]
        block.call
        fs = FormSection.new(name: name.to_sym, label: label, description: description, section_items: section_items)
        self.form_sections = form_sections + [fs]
        if previous_context&.first == :form && previous_context[1] == self
          form_attributes.concat(fs.attribute_names)
          self.form_items = form_items + [fs]
        elsif previous_context&.first == :form_tab && previous_context[1] == self
          previous_context[2] << fs
        end
      ensure
        Thread.current[:madmin_collecting_for] = previous_context
      end

      def form_tab(name, label: name.to_s.humanize, &block)
        tab_items = []
        Thread.current[:madmin_collecting_for] = [:form_tab, self, tab_items]
        proxy = BlockProxy.new(self)
        proxy.instance_exec(&block)
        tab_block = proxy.uses_arbre? ? block : nil
        attribute_names = flatten_to_attribute_names(tab_items)
        self.form_tabs = form_tabs + [FormTab.new(name: name.to_sym, label: label, attribute_names: attribute_names, tab_items: tab_items, tab_block: tab_block)]
      ensure
        Thread.current[:madmin_collecting_for] = nil
      end

      def form_tab_for(name)
        return nil if name.blank?
        form_tabs.find { |t| t.name == name.to_sym }
      end

      def tab_edit_path(record, tab_name)
        url_helpers.polymorphic_path([:madmin, route_namespace, becomes(record)], action: :edit, tab: tab_name)
      end

      def tab_permitted_params(tab_name)
        tab = form_tab_for(tab_name)
        return [] unless tab
        tab.attribute_names.filter_map do |attr_name|
          attr = attributes[attr_name]
          attr&.field&.to_param
        end
      end

      def model(value = nil)
        if value
          @model = value
        else
          @model ||= model_name.constantize
        end
      end

      def model_find(id)
        friendly_model? ? model.friendly.find(id) : model.find(id)
      end

      def model_name
        to_s.chomp("Resource").classify
      end

      def scope(name)
        scopes << name
      end

      def filter(filter_class)
        filters << filter_class
      end

      def get_attribute(name)
        attributes[name]
      end

      def attribute(name, type = nil, **options)
        type ||= infer_type(name)
        field = options.delete(:field) || field_for_type(type)

        if field.nil?
          Rails.logger.warn <<~MESSAGE
            WARNING: Madmin could not infer a field type for `#{name}` attribute in `#{self.name}`. Defaulting to a String type.
            #{caller.find { _1.start_with? Rails.root.to_s }}
          MESSAGE
          field = Fields::String
        end

        config = if field.respond_to?(:build_config)
          field.build_config(options)
        else
          ActiveSupport::OrderedOptions.new.merge(options)
        end
        yield config if block_given?

        # Form is an alias for new & edit
        if config.has_key?(:form)
          config.new = config[:form]
          config.edit = config[:form]
        end

        # New/create and edit/update need to match
        config.create = config[:create] if config.has_key?(:new)
        config.update = config[:update] if config.has_key?(:edit)

        attributes[name] = Attribute.new(
          name: name,
          type: type,
          field: field.new(attribute_name: name, model: model, resource: self, options: config)
        )

        collecting_for, collecting_resource, container_attribute_names = Thread.current[:madmin_collecting_for]
        if collecting_resource == self
          case collecting_for
          when :index
            index_attributes << name
          when :show
            show_attributes << name
          when :form
            form_attributes << name
            form_items << name
          when :form_tab
            container_attribute_names << name
          when :form_section
            container_attribute_names << name
          end
        end
      end

      # Returns singular name
      # For example: "Forum::Post" -> "Forum / Post"
      def friendly_name
        model_name.split("::").map { |part| part.underscore.humanize }.join(" / ").titlecase
      end

      # Support for isolated namespaces
      # Finds parent module class to include in polymorphic urls
      def route_namespace
        return @route_namespace if instance_variable_defined?(:@route_namespace)
        namespace = model.module_parents.detect do |n|
          n.respond_to?(:use_relative_model_naming?) && n.use_relative_model_naming?
        end
        @route_namespace = (namespace ? namespace.name.underscore.to_sym : nil)
      end

      def index_path(options = {})
        url_helpers.polymorphic_path([:madmin, route_namespace, model], options)
      end

      def new_path
        url_helpers.polymorphic_path([:madmin, route_namespace, model], action: :new)
      end

      def show_path(record)
        url_helpers.polymorphic_path([:madmin, route_namespace, becomes(record)])
      end

      def edit_path(record)
        url_helpers.polymorphic_path([:madmin, route_namespace, becomes(record)], action: :edit)
      end

      def becomes(record)
        record.instance_of?(model) ? record : record.becomes(model)
      end

      def param_key
        model.model_name.param_key
      end

      def permitted_params
        attributes.values.filter { |a| a.field.visible?(:form) }.map { |a| a.field.to_param }
      end

      def display_name(record)
        "#{record.class} ##{record.id}"
      end

      def friendly_model?
        model.respond_to? :friendly
      end

      def sortable_columns
        model.column_names
      end

      def searchable_attributes
        attributes.values.select { |a| a.field.searchable? }
      end

      def member_action(&block)
        member_actions << block
      end

      def field_for_type(type)
        {
          binary: Fields::String,
          blob: Fields::Text,
          boolean: Fields::Boolean,
          currency: Fields::Currency,
          date: Fields::Date,
          datetime: Fields::DateTime,
          decimal: Fields::Decimal,
          enum: Fields::Enum,
          float: Fields::Float,
          hstore: Fields::Json,
          integer: Fields::Integer,
          json: Fields::Json,
          jsonb: Fields::Json,
          primary_key: Fields::String,
          select: Fields::Select,
          string: Fields::String,
          text: Fields::Text,
          time: Fields::Time,
          timestamp: Fields::Time,
          timestamptz: Fields::Time,
          password: Fields::Password,
          file: Fields::File,

          # Postgres specific types
          bit: Fields::String,
          bit_varying: Fields::String,
          box: Fields::String,
          cidr: Fields::String,
          circle: Fields::String,
          citext: Fields::Text,
          daterange: Fields::String,
          inet: Fields::String,
          int4range: Fields::String,
          int8range: Fields::String,
          interval: Fields::String,
          line: Fields::String,
          lseg: Fields::String,
          ltree: Fields::String,
          macaddr: Fields::String,
          money: Fields::String,
          numrange: Fields::String,
          oid: Fields::String,
          path: Fields::String,
          point: Fields::String,
          polygon: Fields::String,
          tsrange: Fields::String,
          tstzrange: Fields::String,
          tsvector: Fields::String,
          uuid: Fields::String,
          xml: Fields::Text,

          # Associations
          attachment: Fields::Attachment,
          attachments: Fields::Attachments,
          belongs_to: Fields::BelongsTo,
          polymorphic: Fields::Polymorphic,
          has_many: Fields::HasMany,
          has_one: Fields::HasOne,
          rich_text: Fields::RichText,
          nested_has_many: Fields::NestedHasMany,
          nested_has_one: Fields::NestedHasOne
        }[type]
      end

      def infer_type(name)
        name_string = name.to_s

        if model.attribute_types.include?(name_string)
          column_type = model.attribute_types[name_string]
          if column_type.is_a? ::ActiveRecord::Enum::EnumType
            :enum
          else
            column_type.type || :string
          end
        elsif (association = model.reflect_on_association(name))
          type_for_association(association)
        elsif model.reflect_on_association(:"rich_text_#{name_string}")
          :rich_text
        elsif model.reflect_on_association(:"#{name_string}_attachment")
          :attachment
        elsif model.reflect_on_association(:"#{name_string}_attachments")
          :attachments

        # has_secure_password
        elsif model.attribute_types.include?("#{name_string}_digest") || name_string.ends_with?("_confirmation")
          :password

          # ActiveRecord Store
        elsif model_store_accessors.include?(name)
          :string
        end
      end

      def type_for_association(association)
        if association.has_one?
          :has_one
        elsif association.collection?
          :has_many
        elsif association.polymorphic?
          :polymorphic
        else
          :belongs_to
        end
      end

      def url_helpers
        @url_helpers ||= Rails.application.routes.url_helpers
      end

      def model_store_accessors
        store_accessors = model.stored_attributes.values
        store_accessors.flatten
      end

      def menu(options)
        @menu_options = options
      end

      def menu_options
        return false if @menu_options == false
        @menu_options ||= {}
        return false if @menu_options[:hidden]
        @menu_options.with_defaults(label: friendly_name.pluralize, url: index_path)
      end

      private

      def flatten_to_attribute_names(items)
        items.flat_map do |item|
          item.is_a?(FormSection) ? item.attribute_names : [item]
        end
      end
    end
  end
end
