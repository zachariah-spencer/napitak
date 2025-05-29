# Inventory wraps a Deck to manage card collections (e.g. ingredients or potions).
class Inventory
    attr_reader :deck

    # Initialize with an optional array of card instances
    def initialize(cards = [])
        @deck = Deck.new(cards)
        @in_hand = []
    end

    # Draw a card from the inventory (reshuffles automatically if needed)
    def draw(random_sample = false)
        deck.draw(random_sample)
    end

    # Add a card back into the inventory (to the draw pile)
    def add(card)
        deck.add(card)
    end

    # Move a card to the discard pile
    def discard(card)
        deck.discard(card)
    end

    def remove(card)
        deck.remove(card)
    end

    # How many cards remain in the draw pile?
    def size
        deck.size
    end

    # True if no cards are left to draw
    def empty?
        deck.empty?
    end

    # Returns all cards currently in the inventory (draw + discard)
    def all_cards
        deck.draw_pile + deck.discard_pile
    end

    def all_ingredients()
        deck.draw_pile + deck.discard_pile + @in_hand
    end

    def grab(card)
        deck.remove(card)
        @in_hand.append(card)
    end

    def return(card)
        deck.add(card)
        @in_hand.delete(card)
    end

end