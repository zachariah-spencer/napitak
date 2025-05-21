class AlchemyTable
    attr_gtk
    attr

    def initialize(recipe_book, max_uses:)
        @sc_id = "alchemy_table"
        @player = $player
        @recipe_book = recipe_book
        @uses_left = max_uses
    end

    def cleanup()
        puts 'cleanup alchemy_table.rb'
    end

    def craft_or_refresh(player, recipe_or_potion); end

    def leave_early(player); end

    def tick()

        $game.change_scene(prev_sc: @sc_id, next_sc: 'combat') if GTK.args.inputs.keyboard.key_down.p

    end

    def calc(); end

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

            l2 << [ encounter_label ]
            return l2
        when 3
            return l3
        when 4
            return l4
        else
        # puts "combat.rb: Invalid Render Argument"
        end
    end
end


    # toggle_card_selected card
    # @matching_potion = check_selected_cards_for_potion

    # def toggle_card_selected c
    #     move_card(c, @selected_cards, @hand) if not c.selected else move_card(c, @hand, @selected_cards)
    # end

    # def unselect_cards
    #     @selected_cards.each do |id, c|
    #     toggle_card_selected c
    #     end
    # end
    # 
    # # Helper method: builds a frequency hash for an array
    # def ingredient_counts ingredients
    #     ingredients.each_with_object(Hash.new(0)) do |ingredient, counts|
    #     counts[ingredient] += 1
    #     end
    # end
    # 
    # # Call this method (for example, after adding a new ingredient card)
    # def check_selected_cards_for_potion
    #     # Extract the id's from all currently selected ingredient cards.
    #     selected_ids = @selected_cards.values.map &:id

    #     # Build a frequency hash of selected ingredient IDs.
    #     selected_counts = ingredient_counts selected_ids
 
    #     matching_potion = nil
 
    #     # Iterate through each potion definition in $pids.
    #     $pids.each do |potion_id, potion|
    #     # Build a frequency hash for the potion's ingredient list.
    #     required_counts = ingredient_counts potion[:ingredients]
    #     
    #     # Check if the counts (and thus the ingredients including repeats) match exactly.
    #     if selected_counts == required_counts
    #         puts "Matching potion found: #{potion[:name]}"
    #         matching_potion = { id: potion_id, data: potion }
    #         break  # Exit once a match is found, or remove break if you want to find all matches.
    #     end
    #     end
 
    #     unless matching_potion
    #     puts "No matching potion for selected ingredients: #{selected_ids}"
    #     end
 
    #     matching_potion
    # end

    # def potion? cid
    #     cid[0] == "p"
    # end

    # def calc_keyboard_inputs
        # WILL MOVE TO CRAFTING ENCOUNTER
        #
        #
        # if @matching_potion and inputs.keyboard.key_down.space 

        #   c = gen_new_card @matching_potion.id
        #   move_card c, @hand, @deck

        #   @selected_cards.each do |id, c|
        #     @deck.discard c
        #     @hand.delete c.entity_id
        #     @selected_cards.delete c.entity_id
        #   end

        #   @matching_potion = nil
        # end
    # end

=begin
        if @matching_potion
        craftable_potion_tooltip ||= [
            {
            x: grid.w / 2,
            y: grid.h / 2,
            text: "Press SPACE BAR to finalize brew!",
            anchor_x: 0.5,
            anchor_y: 0.5,
            size_enum: 10,
            r: 255,
            },
            {
            x: grid.w / 2,
            y: grid.h / 2 + 75,
            text: "#{@matching_potion.data.name}",
            anchor_x: 0.5,
            anchor_y: 0.5,
            size_enum: 10,
            r: 255,
            }
        ]
        l3 << [ craftable_potion_tooltip ]
        end
=end

=begin

    def move_card c, to, from = nil
        if to == @hand && @hand.length == @max_hand_size
            puts "ERROR: Max Hand Size Reached"
            return
        end

        to[c.entity_id] = c
        from.delete c.entity_id if from

        if to == @hand && from == nil
            c.pos.x = 20
            c.pos.y = 200
        elsif to == @hand && from == @selected_cards
            c.selected = false
            c.fw = 160
            c.fh = 160
            c.grabbed = false
            c.padding = -60.0
        elsif to == @selected_cards && from == @hand
            c.selected = true
            c.fw = 250
            c.fh = 250
            c.grabbed = false
            c.padding = 5.0
        end

    end

=end