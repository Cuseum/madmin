module Madmin
  module Fields
    class TabledHasMany < HasMany
      # Config is a special ActiveSupport::OrderedOptions subclass that adds an
      # `index` method for capturing the index block and collecting attribute names
      # during resource class definition. All other option lookups (fetch, has_key?,
      # [], method_missing getters/setters) are inherited from OrderedOptions.
      class Config < ActiveSupport::OrderedOptions
        attr_reader :tabled_index_block, :tabled_index_attributes, :tabled_uses_arbre

        def index(&block)
          @tabled_index_block = block
          @tabled_index_attributes = []
          @tabled_uses_arbre = false
          proxy = IndexBlockProxy.new(self)
          proxy.instance_exec(&block) if block
          @tabled_uses_arbre = proxy.uses_arbre?
        end

        # Proxy used during class definition to collect attribute names from the
        # index block, mirroring Madmin::Resource::BlockProxy.
        class IndexBlockProxy
          def initialize(config)
            @config = config
            @uses_arbre = false
          end

          def uses_arbre?
            @uses_arbre
          end

          def attribute(name, *_args, **_kwargs)
            @config.tabled_index_attributes << name
          end

          def row(*_args, **_kwargs, &block)
            @uses_arbre = true
            instance_exec(&block) if block
          end

          def col(*_args, **_kwargs, &block)
            @uses_arbre = true
            instance_exec(&block) if block
          end

          def method_missing(_name, *_args, **_kwargs, &block)
            @uses_arbre = true
            instance_exec(&block) if block
          end

          def respond_to_missing?(_name, _include_private = false)
            true
          end
        end

        private_constant :IndexBlockProxy
      end

      # Returns a Config instance pre-populated with the given options hash.
      # Called by Madmin::Resource#attribute instead of the default
      # ActiveSupport::OrderedOptions.new.merge(options) when this field class is used.
      def self.build_config(options)
        config = Config.new
        options.each { |k, v| config[k] = v }
        config
      end

      def index_block
        options.tabled_index_block
      end

      def index_attributes
        options.tabled_index_attributes || []
      end

      def uses_arbre?
        options.tabled_uses_arbre || false
      end

      # Returns Attribute objects from the associated resource for each name
      # collected from the index block, in declaration order.
      def index_attribute_objects
        return [] unless associated_resource
        index_attributes.filter_map { |name| associated_resource.attributes[name] }
      end
    end
  end
end
