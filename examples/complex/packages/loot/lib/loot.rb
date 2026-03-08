# frozen_string_literal: true

# Loot package entry point — has its own gem dependency (dotenv ~> 2.0)
# Add all sibling packages' lib dirs to $LOAD_PATH for cross-package imports.
packages_dir = File.expand_path('../..', __dir__)
Dir.glob("#{packages_dir}/*/lib") do |d|
  $LOAD_PATH.unshift(d) unless $LOAD_PATH.include?(d)
end

require 'json'
require 'open3'
require 'rbconfig'

require 'loot/item'

# Cross-package import by name (quest lib is on $LOAD_PATH)
Quests = import('quest')

module Loot
  LIST_SEPARATOR = '|'

  DOTENV_PAYLOAD =
    begin
      env_file = File.expand_path('../.env', __dir__)
      gemfile = File.expand_path('../gems.rb', __dir__)
      script = <<~'RUBY'
        require 'json'
        require 'bundler/setup'
        require 'dotenv'

        config = Dotenv.parse(ARGV.fetch(0))
        version = Gem.loaded_specs.fetch('dotenv').version.to_s
        puts JSON.generate(version:, config:)
      RUBY

      output, status =
        Open3.capture2e(
          { 'BUNDLE_GEMFILE' => gemfile },
          RbConfig.ruby,
          '-e',
          script,
          env_file,
        )
      unless status.success?
        raise RuntimeError, "failed to load loot dotenv bundle: #{output}"
      end

      JSON.parse(output)
    end

  CONFIG = DOTENV_PAYLOAD.fetch('config')
  DOTENV_VERSION = DOTENV_PAYLOAD.fetch('version')

  KITS_BY_TIER = {
    common: CONFIG.fetch('COMMON_KITS', '').split(LIST_SEPARATOR),
    uncommon: CONFIG.fetch('UNCOMMON_KITS', '').split(LIST_SEPARATOR),
    rare: CONFIG.fetch('RARE_KITS', '').split(LIST_SEPARATOR),
    epic: CONFIG.fetch('EPIC_KITS', '').split(LIST_SEPARATOR),
  }.freeze

  def self.suggest_kit(difficulty: :medium, weather: :clear)
    tier =
      case difficulty
      when :easy
        :common
      when :medium
        :uncommon
      when :hard
        :rare
      when :legendary
        :epic
      else
        :common
      end

    weather_key = "WEATHER_#{weather.to_s.upcase}"
    weather_boost =
      CONFIG.fetch(
        weather_key,
        CONFIG.fetch('WEATHER_DEFAULT', 'Spare batteries'),
      )
    planner_name = Quests.fetch(:planner_name)

    Item.random(
      tier:,
      weather:,
      weather_boost:,
      planner_name:,
      kits_by_tier: KITS_BY_TIER,
    )
  end
end

export(
  Loot:,
  suggest_kit: Loot.method(:suggest_kit),
  VERSION: '0.2.0',
  DOTENV_VERSION: Loot::DOTENV_VERSION,
)
