require_relative 'quest/challenge'

module Quest
  DIFFICULTY_LEVELS = %i[easy medium hard legendary].freeze

  def self.random_quest(difficulty: :medium)
    challenges = Challenge.generate(difficulty)
    { name: Challenge::QUEST_NAMES.sample, difficulty:, challenges: }
  end
end

export(
  Quest:,
  random_quest: Quest.method(:random_quest),
  MAX_CHALLENGES: 5,
  version: '1.0.0'
)
