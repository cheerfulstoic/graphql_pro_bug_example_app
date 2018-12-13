
module Types
  module TestInterface
    include ApplicationFields
    include Types::BaseInterface

    orphan_types Types::PirateType

    multiple_records_field :ships, Ship
  end
end
