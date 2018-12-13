# frozen_string_literal: true

require 'types/connections/active_record_connection'
# require 'types/application_enum'

module GraphQL
  module ApplicationClassGenerator
    class << self
      extend Memoist

      # Assumes that we're working with an ActiveRecord model class
      def active_record_connection_type(type_class)
        connection_name = type_class.graphql_name + 'RecordConnection'
        edge_type_class = type_class.edge_type
        Class.new(::Types::Connections::ActiveRecordConnection) do
          graphql_name(connection_name)
          edge_type(edge_type_class)
        end
      end
      memoize :active_record_connection_type

      def model_scopes_enum_class(type_class)
        Class.new(::Types::BaseEnum) do
          graphql_name(type_class.graphql_name + 'Scopes')
          type_class.scope_attributes.each do |name, description|
            value name.to_s.upcase, description, value: name
          end
        end
      end
      memoize :model_scopes_enum_class
    end
  end
end
