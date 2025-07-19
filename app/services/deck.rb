# A simple Deck abstraction to manage drawing, discarding, and reshuffling cards.
class Deck
  attr_reader :draw_pile, :discard_pile

  # Initialize with an optional array of cards.
  def initialize(cards = [])
    @draw_pile = Array(cards).flatten.dup
    @discard_pile = []
  end

  # Add a card into the draw pile.
  def add(card)
    @draw_pile << card
  end

  def check_for_reshuffle
    if @draw_pile.empty? && !@discard_pile.empty?
      reshuffle 
      $player.add_stun(1)
    end
  end

  # Draw a card: reshuffle if needed, then remove and return one.
  def draw(random_sample = false)
    GTK.args.audio[:card_draw] = { input: "sounds/sfx/card/SFX_Card4.wav" }
    
    if random_sample
      card = (@draw_pile + @discard_pile).sample()
      @draw_pile.delete(card)
      card
    else
      reshuffle if @draw_pile.empty? && !@discard_pile.empty?
      card = @draw_pile.sample
      @draw_pile.delete(card)
      card
    end
  end

  # Discard a card into the discard pile.
  def discard(card)
    # @discard_pile << card
    @draw_pile << card
  end

  def remove(card)
    @draw_pile.delete(card)
    card
  end

  # Move all discarded cards back into the draw pile and shuffle.
  def reshuffle
    @draw_pile.concat(@discard_pile)
    @discard_pile.clear
    @draw_pile.shuffle!
  end

  # Number of cards remaining in the draw pile.
  def size
    @draw_pile.size
  end

  def discard_size
    @discard_pile.size
  end

  # Check whether the draw pile is empty.
  def empty?
    @draw_pile.empty?
  end
end
