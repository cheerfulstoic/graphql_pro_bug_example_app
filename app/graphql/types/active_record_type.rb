# frozen_string_literal: true

require 'application_class_generator'

module Types
  class ActiveRecordType < Types::BaseObject
    field :id, Integer, 'DB ID', null: false

    class << self
      extend Memoist

      attr_writer :model_class_name

      COLUMN_TYPE_MAP = {
        string: GraphQL::Types::String,
        integer: GraphQL::Types::Int,
      }.freeze

      def attribute_field(name, options = {})
        base_options = options.slice(:description, :deprecation_reason, :method)

        column_object = column_object(name)
        if column_object(name)
          type = COLUMN_TYPE_MAP[column_object.type]
          field name, type, base_options.merge(null: column_object.null)
        elsif model_class.try(:translated_attribute_names)&.include?(name.to_sym)
          field name, GraphQL::Types::String, { null: true }.merge(base_options)
        elsif model_class.method_defined?(base_options.fetch(:method, name))
          type = options.fetch(:type, GraphQL::Types::String)

          field name, type, { null: true }.merge(base_options)
        else
          raise ArgumentError, "Method `#{name}` could not be determined on #{self.name}"
        end
      end

      def has_many_field(name, options = {}, &block) # rubocop:disable Naming/PredicateName
        type_class = association_type_class(model_class, options.fetch(:method, name), options[:type])

        field name, GraphQL::ApplicationClassGenerator.active_record_connection_type(type_class),
              options.slice(:description, :method, :scope).merge(null: false) do
          instance_eval(&block) if block
        end

        define_method(name) do
          # Return array so that GraphQL connections don't cause N+1 queries due to default_max_page_size
          object.send(name).to_a
        end
      end

      def has_one_field(name, options = {}, &block) # rubocop:disable Naming/PredicateName
        type_class = association_type_class(model_class, options.fetch(:method, name), options[:type])

        field name, type_class, { null: false }.merge(options.slice(:description, :null, :method)) do
          instance_eval(&block) if block
        end
      end

      def scope_attribute(name, description = nil)
        @scope_attributes ||= {}
        @scope_attributes[name.to_sym] = description
      end

      def scope_attributes
        @scope_attributes || {}
      end

      def paperclip_image_url_field(name, _options = {})
        styles = model_class.new.send(name).styles

        field "#{name}_url", String, null: false, description: paperclip_styles_description(styles) do
          prepare = lambda { |style, _ctx|
            raise GraphQL::ExecutionError, "Invalid style: `#{style}`" unless styles.key?(style.to_sym)

            style
          }
          argument :style, String, required: true, prepare: prepare
        end

        define_method("#{name}_url") do |style:|
          object.send(name).url(style)
        end
      end

      def association_type_class(model_class, association_name, default_type)
        default_type&.constantize ||
          model_type_class(model_class.reflect_on_association(association_name).klass)
      end

      def column_object(attribute_name)
        # Take care of models using the TableMapper concern
        column_name = (model_class.try(:table_mapped_names) || {}).fetch(attribute_name, attribute_name)

        object = model_class.column_for_attribute(column_name == true ? attribute_name : column_name)
        object unless object.is_a?(ActiveRecord::ConnectionAdapters::NullColumn)
      end

      def model_class
        (@model_class_name || to_s.match(/\ATypes::(.*)Type\Z/)&.[](1))&.constantize
      end
      memoize :model_class

      private

      MODIFIER_DESCRIPTIONS = { '#' => 'center cropped', '>' => 'shrink if needed' }.freeze

      def paperclip_styles_description(styles)
        description = 'Supported styles:'
        styles.inject(description) do |result, (key, style)|
          size, modifier = style.geometry.match(/^(\d+x\d+)([\#\>])$/).to_a[1..-1]
          modifier_description = MODIFIER_DESCRIPTIONS[modifier]

          "#{result}\n\n`#{key}`: #{size}#{" (#{modifier_description})" if modifier_description}"
        end
      end
    end
  end
end
