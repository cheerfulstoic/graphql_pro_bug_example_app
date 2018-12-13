module Types
  # class ShipType < Types::BaseObject
  class ShipType < ActiveRecordType
    pundit_role nil

    # field :id, Integer, null: false
    # field :name, String, null: false

    attribute_field :name

    has_one_field :pirate
    # field :pirate, PirateType, null: false
  end
end


