# frozen_string_literal: true

# Quest package entry point — no gem dependencies
# Add all sibling packages' lib dirs to $LOAD_PATH for cross-package imports.
packages_dir = File.expand_path('../..', __dir__)
Dir.glob("#{packages_dir}/*/lib") do |d|
  $LOAD_PATH.unshift(d) unless $LOAD_PATH.include?(d)
end

Challenge = import_relative('quest/challenge')

ROOT_EXAMPLE_GEM_AVAILABLE =
  begin
    require 'root_only_toolkit'
    true
  rescue LoadError
    false
  end

module Quest
  TEAM_NAME = 'Waypoint Council'
  DIFFICULTY_LEVELS = %i[easy medium hard legendary].freeze
  MAX_STAGES = 4

  def self.plan_route(destination:, departure_at:, difficulty: :medium)
    normalized_difficulty =
      (DIFFICULTY_LEVELS.include?(difficulty) ? difficulty : :medium)

    {
      destination:,
      departure_at:,
      difficulty: normalized_difficulty,
      weather: Challenge.weather_for(destination),
      lead: Challenge.lead,
      stages: Challenge.generate(normalized_difficulty, max_steps: MAX_STAGES),
    }
  end
end

export(
  Quest:,
  plan_route: Quest.method(:plan_route),
  MAX_STAGES: Quest::MAX_STAGES,
  planner_name: 'Trail Planner',
  version: '2.1.0',
  root_example_gem_available?: ROOT_EXAMPLE_GEM_AVAILABLE,
)
