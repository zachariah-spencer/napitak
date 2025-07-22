class GameContext
  attr_accessor :files, :player, :recipe_book, :encounter_manager, :game

  def initialize(files:, player:, recipe_book:, encounter_manager:)
    @files = files
    @player = player
    @recipe_book = recipe_book
    @encounter_manager = encounter_manager
  end
end
