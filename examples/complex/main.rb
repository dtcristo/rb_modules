# frozen_string_literal: true

require_relative '../../lib/package'

# Add all package lib dirs to $LOAD_PATH so packages can be imported by name.
packages_dir = File.expand_path('packages', __dir__)
Dir.glob("#{packages_dir}/*/lib") do |d|
  $LOAD_PATH.unshift(d) unless $LOAD_PATH.include?(d)
end

adventure_entry =
  File.expand_path('packages/adventure/lib/adventure.rb', __dir__)
loot_entry = File.expand_path('packages/loot/lib/loot.rb', __dir__)

# --- 1. Single Import ---
ENV['BUNDLE_GEMFILE'] = File.expand_path('packages/adventure/gems.rb', __dir__)
Adventure = import adventure_entry

# --- 2. Namespace Import (hash export) ---
ENV.delete('BUNDLE_GEMFILE')
Plans = import 'quest'

# --- 3. Destructuring Import + fetch_values ---
ENV.delete('BUNDLE_GEMFILE')
import(loot_entry) => {
  suggest_kit:, VERSION: loot_version, DOTENV_VERSION: loot_dotenv_version
}

# --- 4. fetch_values ---
max_stages, planner_version = Plans.fetch_values(:MAX_STAGES, :version)
planner_name = Plans.fetch(:planner_name)
root_example_gem_available = Plans.fetch(:root_example_gem_available?)

# --- 5. Constant access via namespace ---
QuestModule = Plans::Quest

departure_at = Adventure.parse_time('tomorrow 09:00')
expedition =
  Plans.plan_route(
    destination: 'Crystal Caves',
    difficulty: :hard,
    departure_at:,
  )

puts '=' * 64
narrator = Adventure.create_narrator
lead = Adventure.create_character(codename: expedition[:lead])

narrator.announce("🧭 #{lead} prepares for #{expedition[:destination]}")
narrator.announce("   Motto: \"#{lead.motto}\"")
puts

narrator.announce(
  "📜 Route difficulty: #{expedition[:difficulty]} " \
    "| Departure: #{expedition[:departure_at].strftime('%Y-%m-%d %H:%M')}",
)
narrator.describe("Max stages allowed: #{max_stages}")
narrator.describe(
  "#{planner_name} v#{planner_version} | Loot system v#{loot_version}",
)
narrator.describe(
  "Adventure dotenv v#{Adventure.dotenv_version} | Loot dotenv v#{loot_dotenv_version}",
)
narrator.describe(
  "Root Gemfile gem visible inside quest package: #{root_example_gem_available}",
)
puts

expedition[:stages].each_with_index do |stage, i|
  narrator.describe("Stage #{i + 1}: #{stage}")
  item =
    suggest_kit.(
      difficulty: expedition[:difficulty],
      weather: expedition[:weather],
    )
  narrator.describe("  → Kit: #{item}")
end

puts
narrator.victory(
  "✅ #{QuestModule::TEAM_NAME} approves #{lead.name}'s expedition plan!",
)
puts '=' * 64
