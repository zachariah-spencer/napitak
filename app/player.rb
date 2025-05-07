class Player
    attr_accessor :hp, :max_hp, :focus, :max_focus

    def initialize
        $player = self

        @my_turn = false
        @hp = 20
        @max_hp = 20
        @focus = 0
        @max_focus = 2
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
