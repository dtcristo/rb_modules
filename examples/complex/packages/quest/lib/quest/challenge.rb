module Quest
  class Challenge
    QUEST_NAMES = [
      'The Dragon of Mount Doom',
      'The Lost Temple of Ruby',
      'The Goblin King\'s Riddle',
      'The Enchanted Forest',
      'The Siege of Syntax Castle'
    ].freeze

    CHALLENGES = {
      easy: [
        'Cross the rickety bridge',
        'Solve the farmer\'s riddle',
        'Find the hidden key'
      ],
      medium: [
        'Defeat the troll guardian',
        'Navigate the maze of mirrors',
        'Decode the ancient scroll'
      ],
      hard: [
        'Battle the shadow knight',
        'Survive the fire swamp',
        'Outsmart the sphinx'
      ],
      legendary: [
        'Slay the elder dragon',
        'Break the curse of eternity',
        'Conquer the tower of trials'
      ]
    }.freeze

    def self.generate(difficulty)
      pool = CHALLENGES.fetch(difficulty, CHALLENGES[:medium])
      count = case difficulty
              when :easy then 1
              when :medium then 2
              when :hard then 3
              when :legendary then 4
              else 2
              end
      pool.sample(count)
    end
  end
end
