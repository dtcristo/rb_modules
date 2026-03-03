# Adventure package entry point — has its own gem dependencies (faker, colorize)
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../gems.rb', __dir__)
require 'bundler/setup'

require_relative 'adventure/character'
require_relative 'adventure/narrator'

module Adventure
  def self.create_character = Character.new
  def self.create_narrator = Narrator.new
end

export Adventure
