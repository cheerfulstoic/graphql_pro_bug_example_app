# frozen_string_literal: true

require 'application_class_generator'

module Types
  module ApplicationFields
    extend ActiveSupport::Concern

    CAMELIZE_SCOPE = ->(name) { name.to_s.camelize(:lower) }
    UNDERSCORE_SCOPE = ->(name) { name.to_s.underscore.to_sym }

    module ClassMethods
      def model_type_class(model_class)
        "Types::#{model_class}Type".constantize
      end

      def resource_fields(name, model_class, options = {})
        multiple_records_field(name, model_class, options)
        singular_record_field(name.to_s.singularize, model_class, options)
      end

      # Helper for rendering a list of ActiveRecord records
      def multiple_records_field(name, model_class, options = {})
        type_class = model_type_class(model_class)

        enum_class = GraphQL::ApplicationClassGenerator.model_scopes_enum_class(type_class)
        field name, GraphQL::ApplicationClassGenerator.active_record_connection_type(type_class),
              null: false, extras: [:ast_node], method: :"_#{name}", description: options[:description] do
          argument :scopes, [enum_class], required: false if type_class.scope_attributes.present?
        end

        define_method(:"_#{name}") do |**kwargs|
          requested_association_names = requested_association_names(model_class, kwargs.delete(:ast_node))
          given_scope_attributes = (kwargs.delete(:scopes) || []).map(&UNDERSCORE_SCOPE)

          objects = if respond_to?(name)
                      # See https://bugs.ruby-lang.org/issues/10856
                      kwargs.empty? ? public_send(name) : public_send(name, **kwargs)
                    else
                      model_class.all
                    end
          objects.includes!(*requested_association_names) if requested_association_names.present?
          # given_scope_attributes.inject(objects) { |results, scope_attribute| results.public_send(scope_attribute) }
          objects
        end
      end

      # Helper for rendering a single ActiveRecord record
      def singular_record_field(name, model_class, options = {})
        type_class = model_type_class(model_class)

        singular_resource_field(name, type_class, options)

        define_method(name) do |id:|
          model_class.find(id)
        end
      end

      # Helper to define a generic single resource field
      def singular_resource_field(name, type_class, options = {})
        field(name, type_class,
              null: false,
              description: "For fetching a single #{name.to_s.humanize.downcase} (#{options[:description]})") do
          argument :id, Integer, required: true,
                                 description: "The database ID to lookup the #{name.to_s.humanize.downcase}"
        end
      end
    end

    def requested_association_names(model_class, ast_node)
      model_class.reflections.keys & (ast_node_dig(ast_node, 'edges', 'node')&.children&.map(&:name) || [])
    end

    def ast_node_dig(ast_node, *fields)
      fields.inject(ast_node) do |node, field|
        node&.children&.detect { |child| child.name == field }
      end
    end
  end
end
