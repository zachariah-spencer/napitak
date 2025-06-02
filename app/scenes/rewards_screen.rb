class RewardsScreen
    attr_gtk
    attr

    def initialize()
        puts "init RewardsScreen"
        @sc_id = "rewards_screen"
    end

    def cleanup
        puts "cleanup"
    end

    def tick
        puts "tick"
        $game.change_scene(prev_sc: @sc_id, next_sc: "alchemy_table") if GTK.args.inputs.keyboard.key_down.p
    end

    def render(layer_num)
        puts "render"
    end
end