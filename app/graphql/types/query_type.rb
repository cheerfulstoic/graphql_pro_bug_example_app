module Types
  class QueryType < Types::BaseObject
    multiple_records_field :pirates_cursor_issue, Pirate

    def pirates_cursor_issue
      Pirate.joins(:ships).includes(:ships)
    end

    field :pundit_issue, [PirateType], null: true

    def pundit_issue
      Pirate.all
    end

    multiple_records_field :ships, Ship

    def ships
      Ship.all # includes(:pirate)
    end
  end
end
