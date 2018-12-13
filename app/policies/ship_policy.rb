class ShipPolicy < ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      puts "ShipPolicy @scope: #{@scope.inspect}"
      @scope.where('ships.name != "foo"')
    end
  end
end

