# frozen_string_literal: true

module Loot
  class Item
    attr_reader :name, :tier, :weather, :weather_boost, :planner_name

    def initialize(name:, tier:, weather:, weather_boost:, planner_name:)
      @name = name
      @tier = tier
      @weather = weather
      @weather_boost = weather_boost
      @planner_name = planner_name
    end

    def to_s
      "#{@name} [#{@tier}] for #{@weather} weather " \
        "(+#{@weather_boost}, via #{@planner_name})"
    end

    def self.random(
      tier:,
      weather:,
      weather_boost:,
      planner_name:,
      kits_by_tier:
    )
      kits = kits_by_tier.fetch(tier, kits_by_tier.fetch(:common))
      name = kits.sample || 'Backup ration pack'
      new(name:, tier:, weather:, weather_boost:, planner_name:)
    end
  end
end
