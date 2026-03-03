require_relative '../../lib/rb/package'

# --- 1. Single Import ---
# Adventure package uses faker + colorize gems internally (bundler/setup)
Adventure = import_relative 'packages/adventure/lib/adventure'

# --- 2. Namespace Import (hash export) ---
Quests = import_relative 'packages/quest/lib/quest'

# --- 3. Destructuring Import ---
import_relative('packages/loot/lib/loot') => { random_drop:, VERSION: loot_version }

# --- 4. fetch / fetch_values ---
max_challenges, quest_version = Quests.fetch_values(:MAX_CHALLENGES, :version)

# --- 5. Constant access via namespace ---
QuestModule = Quests::Quest

puts '=' * 50
narrator = Adventure.create_narrator
hero = Adventure.create_character

narrator.announce("⚔️  #{hero} embarks on a quest!")
narrator.announce("   Catchphrase: \"#{hero.catchphrase}\"")
puts

quest = Quests.random_quest(difficulty: :hard)
narrator.announce("📜 Quest: #{quest[:name]} [#{quest[:difficulty]}]")
narrator.describe("Max challenges allowed: #{max_challenges}")
narrator.describe("Quest system v#{quest_version}, Loot system v#{loot_version}")
puts

quest[:challenges].each_with_index do |challenge, i|
  narrator.describe("Challenge #{i + 1}: #{challenge}")
  item = random_drop.(difficulty: quest[:difficulty])
  narrator.describe("  → Loot: #{item}")
end

puts
narrator.victory("🏆 #{hero.name} conquers all challenges!")
puts '=' * 50
