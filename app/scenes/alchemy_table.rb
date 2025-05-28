class AlchemyTable
    attr_gtk
    attr

    def initialize(max_uses:)
        @sc_id = "alchemy_table"
        @player = $player
        @recipe_book = $recipe_book
        @uses_left = max_uses
        @visible_ingredients = {}
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

        $player.ingredients.all_cards.each do |c|
            puts c.name
        end
    end

    def leave()
        $game.change_scene(prev_sc: @sc_id, next_sc: 'combat')
    end

    def tick()
        calc()
    end

    def calc()
        calc_card_positions

        calc_mouse_inputs

    end

    def calc_card_positions
        @visible_ingredients.each_with_index do |(id, c), i|
            c.calc_position(@visible_ingredients.length, i)
        end
    end

    def render(layer_num)
        l0 = []
        l1 = []
        l2 = []
        l3 = []
        l4 = []

        cards ||= []
        front_card = nil

        @visible_ingredients.each do |id, c|
        prefab = c.prefab

            if c.grabbed
                front_card = prefab
            else
                cards.append prefab
            end
        end

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

            right_panel ||= {
                x: GTK.args.grid.w - 200,
                y: 0,
                w: 200,
                h: GTK.args.grid.h,
                r: 50,
                g: 50,
                b: 50,
                a: 50,
                primitive_marker: :solid,
            }

            l1 << [ left_panel, right_panel ]
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


            l2 << [ encounter_label, craft_btn(), refresh_btn(), leave_btn(), ing_deck(), cards ]
            return l2
        when 3

            l3 << [ front_card ]
            return l3
        when 4
            return l4
        else
        # puts "combat.rb: Invalid Render Argument"
        end
    end

    def craft_btn()

        GTK.args.outputs[:craft_btn].w = 150
        GTK.args.outputs[:craft_btn].h = 75

        GTK.args.outputs[:craft_btn].primitives << {
            x: 0,
            y: 0,
            w: 150,
            h: 75,
            angle: 0,
            r: 0,
            g: 0,
            b: 0,
            primitive_marker: :solid,
        }

        GTK.args.outputs[:craft_btn].primitives << {
            x: 5,
            y: 5,
            w: 140,
            h: 65,
            angle: 0,
            r: 255,
            g: 20,
            b: 20,
            primitive_marker: :solid,
        }

        GTK.args.outputs[:craft_btn].primitives << {
            x: 150 / 2,
            y: 75 / 2,
            text: "CRAFT",
            anchor_x: 0.5,
            anchor_y: 0.5,
            r: 0,
            g: 0,
            b: 0,
            size_enum: 3,
        }

        {
            x: GTK.args.grid.w - 175,
            y: GTK.args.grid.h - 100,
            w: 150,
            h: 75,
            angle: 0,
            path: :craft_btn,
            primitive_marker: :sprite,
        }
    end

    def refresh_btn()

        GTK.args.outputs[:refresh_btn].w = 150
        GTK.args.outputs[:refresh_btn].h = 75

        GTK.args.outputs[:refresh_btn].primitives << {
            x: 0,
            y: 0,
            w: 150,
            h: 75,
            angle: 0,
            r: 0,
            g: 0,
            b: 0,
            primitive_marker: :solid,
        }

        GTK.args.outputs[:refresh_btn].primitives << {
            x: 5,
            y: 5,
            w: 140,
            h: 65,
            angle: 0,
            r: 20,
            g: 255,
            b: 20,
            primitive_marker: :solid,
        }

        GTK.args.outputs[:refresh_btn].primitives << {
            x: 150 / 2,
            y: 75 / 2,
            text: "REFRESH",
            anchor_x: 0.5,
            anchor_y: 0.5,
            r: 0,
            g: 0,
            b: 0,
            size_enum: 3,
        }

        {
            x: GTK.args.grid.w - 175,
            y: GTK.args.grid.h - (100 * 2),
            w: 150,
            h: 75,
            angle: 0,
            path: :refresh_btn,
            primitive_marker: :sprite,
        }
    end

    def leave_btn()
        
        GTK.args.outputs[:leave_btn].w = 150
        GTK.args.outputs[:leave_btn].h = 75

        GTK.args.outputs[:leave_btn].primitives << {
            x: 0,
            y: 0,
            w: 150,
            h: 75,
            angle: 0,
            r: 0,
            g: 0,
            b: 0,
            primitive_marker: :solid,
        }

        GTK.args.outputs[:leave_btn].primitives << {
            x: 5,
            y: 5,
            w: 140,
            h: 65,
            angle: 0,
            r: 20,
            g: 20,
            b: 255,
            primitive_marker: :solid,
        }

        GTK.args.outputs[:leave_btn].primitives << {
            x: 150 / 2,
            y: 75 / 2,
            text: "LEAVE",
            anchor_x: 0.5,
            anchor_y: 0.5,
            r: 0,
            g: 0,
            b: 0,
            size_enum: 3,
        }

        {
            x: 25,
            y: GTK.args.grid.h - (100),
            w: 150,
            h: 75,
            angle: 0,
            path: :leave_btn,
            primitive_marker: :sprite,
        }
    end

    def ing_deck()
        
        GTK.args.outputs[:ing_deck].w = 160
        GTK.args.outputs[:ing_deck].h = 160

        GTK.args.outputs[:ing_deck].primitives << {
            x: 0,
            y: 0,
            w: 160,
            h: 160,
            angle: 0,
            r: 0,
            g: 0,
            b: 0,
            primitive_marker: :solid,
        }

        GTK.args.outputs[:ing_deck].primitives << {
            x: 5,
            y: 5,
            w: 150,
            h: 150,
            angle: 0,
            r: 255,
            g: 20,
            b: 255,
            primitive_marker: :solid,
        }

        GTK.args.outputs[:ing_deck].primitives << {
            x: 160 / 2,
            y: 160 / 2,
            text: "INGREDIENTS",
            anchor_x: 0.5,
            anchor_y: 0.5,
            r: 0,
            g: 0,
            b: 0,
            size_enum: 3,
        }

        {
            x: 20,
            y: GTK.args.grid.h / 2 - (160 / 2),
            w: 160,
            h: 160,
            angle: 0,
            path: :ing_deck,
            primitive_marker: :sprite,
        }
    end

    def draw_card
        card = $player.ingredients.draw
        $player.ingredients.remove(card)
        @visible_ingredients[card.entity_id] = card



        puts card
        card
    end

    def calc_mouse_inputs()
        if GTK.args.inputs.mouse.click
            if Geometry.intersect_rect? inputs.mouse, craft_btn()
                puts "clicked on crafting_button"
                craft_or_refresh("p001")
            elsif Geometry.intersect_rect? inputs.mouse, refresh_btn()
                puts "click on refresh_btn"
            elsif Geometry.intersect_rect? inputs.mouse, leave_btn()
                puts "clicked on leave_btn"
                leave()
            elsif Geometry.intersect_rect? inputs.mouse, ing_deck()
                puts "clicked on ing_deck"
                # draw_card
            end
        end

        calc_card_drag_inputs()




    end

    def get_card_rects()
        card_rects = []

        # Include all active hand cards
        @visible_ingredients.each do |id, card|
            card_rects << card.rect
        end

        card_rects
    end

    def calc_card_drag_inputs()
        if state.currently_dragging_card_id
                c_ref = @visible_ingredients[state.currently_dragging_card_id]
            else
                c_u_m = Geometry.find_intersect_rect inputs.mouse, get_card_rects
                c_ref = nil
        end

        if Geometry.intersect_rect? inputs.mouse, ing_deck() and inputs.mouse.click
            c_ref = draw_card
            c_u_m = c_ref.rect()
            c_u_m.x = ing_deck().x
            c_u_m.y = ing_deck().y
            c_ref.grabbed = true
        end

        if inputs.mouse.click and c_u_m
            state.currently_dragging_card_id = c_u_m.id
            c_ref = @visible_ingredients[state.currently_dragging_card_id]
            c_ref.grabbed = true

            state.mouse_point_inside_square = 
            {
            x: inputs.mouse.x - c_u_m.x,
            y: inputs.mouse.y - c_u_m.y,
            }
            state.click_hold_time = Kernel.tick_count

        elsif inputs.mouse.held and state.currently_dragging_card_id
            c_ref.pos.x = inputs.mouse.x - state.mouse_point_inside_square.x
            c_ref.pos.y = inputs.mouse.y - state.mouse_point_inside_square.y

        elsif inputs.mouse.up and state.currently_dragging_card_id
            # Re-fetch the card from either group.
            c_ref.f_pos.x = c_ref.pos.x
            c_ref.f_pos.y = c_ref.pos.y
            c_ref.grabbed = false

            if state.click_hold_time.elapsed_time < 20 and (Geometry.distance c_ref.pos, c_ref.f_pos) < 20
                # use_card c_ref
                puts "USE CARD"
            end

            state.currently_dragging_card_id = nil
        end
    end
end