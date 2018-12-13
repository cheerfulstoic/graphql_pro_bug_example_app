module Types
  class BaseObject < GraphQL::Schema::Object
    include ApplicationFields
    include GraphQL::Pro::PunditIntegration::ObjectIntegration
  end
end
