class PiratePolicy < ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      puts "PiratePolicy @scope: #{@scope.inspect}"
      @scope.where('age > 30')
    end
  end
end

