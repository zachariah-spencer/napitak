class Player
    attr_gtk
    attr :ingredients, :potions, :focus, :max_focus, :hp, :max_hp

    def initialize
        $player = self

        @my_turn = true
        @hp = 20
        @max_hp = 20
        @focus = 0
        @max_focus = 2
        
        @ingredients = Inventory.new()
        @potions = Inventory.new()
    end

    # setter
    def my_turn=(value)
        @my_turn = value
    end

    # predicate reader
    def my_turn?
        @my_turn
    end
end
