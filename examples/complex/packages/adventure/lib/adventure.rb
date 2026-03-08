# frozen_string_literal: true

# Adventure package entry point — has its own gem dependencies
# Add all sibling packages' lib dirs to $LOAD_PATH for cross-package imports.
packages_dir = File.expand_path('../..', __dir__)
Dir.glob("#{packages_dir}/*/lib") do |d|
  $LOAD_PATH.unshift(d) unless $LOAD_PATH.include?(d)
end

require 'dotenv'
require 'colorize'
require 'chronic'

require_relative 'adventure/character'
require_relative 'adventure/narrator'

module Adventure
  CONFIG = Dotenv.parse(File.expand_path('../.env', __dir__))
  LIST_SEPARATOR = '|'
  NAMES = CONFIG.fetch('TEAM_NAMES', 'Ada|Linus|Grace').split(LIST_SEPARATOR)
  ROLES =
    CONFIG.fetch('TEAM_ROLES', 'Pathfinder|Engineer|Scout').split(
      LIST_SEPARATOR,
    )
  MOTTOS =
    CONFIG.fetch(
      'TEAM_MOTTOS',
      'Stay curious, stay ready.|Measure twice, hike once.',
    ).split(LIST_SEPARATOR)

  def self.pick(values) = values.sample

  def self.create_character(codename: nil)
    Character.new(
      name: codename || pick(NAMES),
      role: pick(ROLES),
      motto: pick(MOTTOS),
    )
  end

  def self.create_narrator
    Narrator.new(prefix: CONFIG.fetch('NARRATOR_PREFIX', 'Mission Control'))
  end

  def self.dotenv_version = Gem.loaded_specs.fetch('dotenv').version.to_s

  def self.parse_time(expression)
    Chronic.parse(expression) || (Time.now + 86_400)
  end
end

export Adventure
