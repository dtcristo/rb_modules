require 'faker'

module Adventure
  class Character
    attr_reader :name, :title, :catchphrase

    def initialize
      @name = Faker::Name.name
      @title = Faker::Job.title
      @catchphrase = Faker::TvShows::StarTrek.villain
    end

    def to_s = "#{@name} the #{@title}"
  end
end
