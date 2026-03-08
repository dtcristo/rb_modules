# frozen_string_literal: true

module Quest
  class Challenge
    STAGES = {
      easy: [
        'Review map checkpoints',
        'Pack daylight supplies',
        'Confirm basecamp radio channel',
      ],
      medium: [
        'Cross the fog valley before noon',
        'Secure rope anchors on the cliff route',
        'Set up satellite check-in',
      ],
      hard: [
        'Traverse the ice bridge at first light',
        'Tag the hidden cave entrance',
        'Carry backup power through the ridge winds',
      ],
      legendary: [
        'Reach summit relay before storm front',
        'Extract crystal sample at the north wall',
        'Return via the silent pass before midnight',
      ],
    }.freeze

    DESTINATION_WEATHER = {
      'Crystal Caves' => :storm,
      'Sapphire Ridge' => :snow,
      'Sunspire Dunes' => :sun,
    }.freeze

    LEADS = [
      'Captain Ada',
      'Scout Linus',
      'Engineer Grace',
      'Guide Matz',
    ].freeze

    def self.generate(difficulty, max_steps:)
      pool = STAGES.fetch(difficulty, STAGES[:medium])
      pool.first(max_steps)
    end

    def self.weather_for(destination)
      DESTINATION_WEATHER.fetch(destination, :clear)
    end

    def self.lead = LEADS.sample
  end
end

export Quest::Challenge
