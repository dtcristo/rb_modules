# frozen_string_literal: true

module Adventure
  class Character
    attr_reader :name, :role, :motto

    def initialize(name:, role:, motto:)
      @name = name
      @role = role
      @motto = motto
    end

    def to_s = "#{@name} the #{@role}".colorize(:cyan)
  end
end
