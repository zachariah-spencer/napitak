class AlchemyTable
    attr_gtk
    attr

    def initialize(max_uses:)
        @sc_id = "alchemy_table"
        @player = $player
        @recipe_book = $recipe_book
        @uses_left = max_uses
    end

    def cleanup()
        puts 'cleanup alchemy_table.rb'
    end

    def craft_or_refresh(recipe_id)
        if @recipe_book.can_craft?(recipe_id)
            potion = @recipe_book.craft(recipe_id)
            puts "CRAFTED #{potion.name}"
            # status_label(..., "Crafted #{potion.name}!") 
        else
            # status_label(..., "Cannot craft #{recipe_id}") 
            puts "CANNOT CRAFT #{recipe_id}"
        end
    end

    def leave_early(player); end

    def tick()

        calc()

        # debug input to move to combat
        $game.change_scene(prev_sc: @sc_id, next_sc: 'combat') if GTK.args.inputs.keyboard.key_down.p

    end

    def calc()

        calc_mouse_inputs

    end

    def render(layer_num)
        l0 = []
        l1 = []
        l2 = []
        l3 = []
        l4 = []

        case layer_num
        when 0
            
            background ||= 
            {
                x: 0,
                y: 0,
                w: GTK.args.grid.w,
                h: GTK.args.grid.h,
                r: 10,
                g: 10,
                b: 20,
                primitive_marker: :solid,
            }

            l0 << [ background ]

            return l0
        when 1

            left_panel ||= {
                x: 0,
                y: 0,
                w: 200,
                h: GTK.args.grid.h,
                r: 50,
                g: 50,
                b: 50,
                a: 50,
                primitive_marker: :solid,
            }

            l1 << [ left_panel ]
            return l1
        when 2

            encounter_label ||= {
                x: GTK.args.grid.w / 2,
                y: GTK.args.grid.h - 50,
                alignment_enum: 1,
                size_enum: 8,
                r: 255,
                g: 255,
                b: 255,
                text: "Alchemy Table",
                primitive_marker: :label,
            }


            l2 << [ encounter_label, craft_btn() ]
            return l2
        when 3
            return l3
        when 4
            return l4
        else
        # puts "combat.rb: Invalid Render Argument"
        end
    end

    def craft_btn()
        {
            x: GTK.args.grid.w / 2 - 100,
            y: GTK.args.grid.h / 2 - 100,
            w: 200,
            h: 200,
            r: 255,
            g: 20,
            b: 20,
            a: 255,
            primitive_marker: :solid,
        }
    end

    def calc_mouse_inputs()
        if GTK.args.inputs.mouse.click
            if Geometry.intersect_rect? inputs.mouse, craft_btn()
                puts "clicked on crafting_button"
                craft_or_refresh("p001")
            end
        end
    end
end