module Loot
  class Item
    attr_reader :name, :tier, :power

    ITEMS = {
      common: [
        'Wooden Sword', 'Leather Boots', 'Torn Map',
        'Rusty Shield', 'Stale Bread'
      ],
      uncommon: [
        'Iron Axe', 'Chainmail Vest', 'Healing Potion',
        'Silver Ring', 'Enchanted Torch'
      ],
      rare: [
        'Flamebrand Sword', 'Mithril Armor', 'Scroll of Fireball',
        'Dragon Scale Shield', 'Boots of Speed'
      ],
      epic: [
        'Excalibur', 'Cloak of Invisibility', 'Staff of the Archmage',
        'Crown of Kings', 'Amulet of Eternity'
      ]
    }.freeze

    POWER = { common: 1..10, uncommon: 11..25, rare: 26..50, epic: 51..100 }.freeze

    def initialize(name, tier)
      @name = name
      @tier = tier
      @power = rand(POWER.fetch(tier, 1..10))
    end

    def to_s = "#{@name} [#{@tier}] (power: #{@power})"

    def self.random(tier = :common)
      name = ITEMS.fetch(tier, ITEMS[:common]).sample
      new(name, tier)
    end
  end
end
