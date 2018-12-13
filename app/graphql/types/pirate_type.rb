module Types
  # class PirateType < Types::BaseObject
  class PirateType < ActiveRecordType
    implements Types::TestInterface

    pundit_role nil

    # field :id, Integer, null: false
    # field :name, String, null: false
    # field :age, Integer, null: false

    attribute_field :name
    attribute_field :age

    # has_many_field :ships
    multiple_records_field :ships, Ship

    def ships
      Ship.joins(:ships).where(ships: {name: object.ships.pluck(:name)})
    end
  end
end

