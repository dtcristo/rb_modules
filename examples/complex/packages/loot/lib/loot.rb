require_relative 'loot/item'

# Re-import quest to access difficulty levels
Quests = import_relative '../../quest/lib/quest'

module Loot
  def self.random_drop(difficulty: :medium)
    tier = case difficulty
           when :easy then :common
           when :medium then :uncommon
           when :hard then :rare
           when :legendary then :epic
           else :common
           end
    Item.random(tier)
  end
end

export(Loot:, random_drop: Loot.method(:random_drop), VERSION: '0.1.0')
