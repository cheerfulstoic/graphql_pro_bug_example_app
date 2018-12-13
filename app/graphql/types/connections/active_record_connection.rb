# frozen_string_literal: true

module Types
  module Connections
    class ActiveRecordConnection < GraphQL::Types::Relay::BaseConnection
      field :total_count, Integer, null: false do
        argument :column, String, required: false
      end
      def total_count(column: nil)
        if column
          validate_model_column!(column)
          object.nodes.count(column)
        else
          object.nodes.size
        end
      end

      field :total_average, Float, null: false do
        argument :column, String, required: true
      end
      def total_average(column:)
        validate_model_column!(column)

        object.nodes.average(column).to_f.round(2)
      end

      private

      def validate_model_column!(column)
        is_model_column = object.nodes.klass.column_names.include?(column.to_s)

        raise "Not a valid column: #{column}" unless is_model_column
      end
    end
  end
end
