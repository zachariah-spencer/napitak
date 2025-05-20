class Combat
  attr_gtk
  attr

  def initialize

    @turn_stages = {
        drawing_cards: 0,
        playing_hand: 1,
        cleanup: 2,
        enemy_turn: 3,
    }

    @hand = {}
    @selected_cards = {}
    
    @matching_potion = nil
    @max_hand_size = 8
    @turn_stage = nil
    @turn_num = -1


    @player = $player
    @enemy = Enemy.new(10)

    10.times do
      @player.potions.add(gen_new_card("p001"))
    end

    begin_combat

  end
  
  def tick
    calc
    render(10)
  end
  
  def calc
    calc_card_positions
    calc_keyboard_inputs

    if @player.my_turn?
      calc_mouse_inputs
    else
      calc_enemy
    end
    calc_entity_removals
    calc_debug_inputs
  end
  
  def render layer_num
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    cards ||= []
    selected_cards ||= []
    front_card = nil

    @hand.each do |id, c|
      prefab = c.prefab

      if c.grabbed
        front_card = prefab
      else
        cards.append prefab
      end
    end

    range = 255 - 0
    x = (Kernel.tick_count * 10) % (2 * range)
    osc_val = range - (x - range).abs

    case layer_num
    when 0

      background ||= {
        x: 0,
        y: 0,
        w: args.grid.w,
        h: args.grid.h,
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
        h: args.grid.h,
        r: 50,
        g: 50,
        b: 50,
        a: 50,
        primitive_marker: :solid,
      }

      player_hp_label_header ||= {
        x: 100,
        y: grid.h - 225,
        alignment_enum: 1,
        size_enum: 8,
        r: 255,
        g: 255,
        b: 255,
        text: "HP",
        primitive_marker: :label,
      }

      player_hp_label ||= {
        x: 100,
        y: grid.h - 275,
        alignment_enum: 1,
        size_enum: 8,
        r: 0,
        g: 150,
        b: 0,
        text: "#{@player.hp}/#{@player.max_hp}",
        primitive_marker: :label,
      }

      player_focus_label_header ||= {
        x: 100,
        y: grid.h - 125,
        alignment_enum: 1,
        size_enum: 8,
        r: 255,
        g: 255,
        b: 255,
        text: "FOCUS",
        primitive_marker: :label,
      }

      player_focus_label ||= {
        x: 100,
        y: grid.h - 175,
        alignment_enum: 1,
        size_enum: 8,
        r: 0,
        g: 150,
        b: 150,
        text: "#{@player.focus}",
        primitive_marker: :label,
      }

      l1 << [ left_panel, @enemy.render(1),player_hp_label_header, player_hp_label, player_focus_label_header, player_focus_label ]
      return l1

    when 2
      deck_sprite ||= {
        x: 20,
        y: 20,
        w: 160,
        h: 160,
        r: 80,
        g: 20,
        b: 80,
        primitive_marker: :solid,
      }

      deck_card_count_label ||= {
        text: "#{@player.potions.size}",
        x: 100,
        y: 100,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_enum: 10,
        r: 255,
        g: 255,
        b: 255,
        primitive_marker: :label,
      }

      pass_button ||= {
        x: 20,
        y: grid.h - 50 - (60 / 2),
        w: 160,
        h: 60,
        r: 100,
        g: 20,
        b: 20,
        primitive_marker: :solid,
      }

      pass_button_label ||= {
        x: 20 + (pass_button.w / 2),
        y: grid.h - (pass_button.h / 2),
        text: "PASS",
        size_enum: 10,
        alignment_enum: 1,
        r: 255,
        g: 255,
        b: 255,
        primitive_marker: :label,
      }

      players_turn_label ||= {
        x: grid.w / 2,
        y: grid.h / 2,
        size_enum: 10,
        r: 255,
        g: 255,
        b: 255,
        a: osc_val,
        alignment_enum: 1,
        text: "YOUR TURN",
      }

      if @player.my_turn?
        l2 << players_turn_label
      end

      @selected_cards.each { |id, c| selected_cards.append c.prefab }


      l2 << [ deck_sprite, deck_card_count_label, pass_button, pass_button_label, cards, selected_cards ]
      return l2

    when 3

      l3 << [ front_card ]
      return l3

    when 4
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end

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
  end

  def calc_enemy
    if @enemy.turn_start_tick_count.elapsed_time == 1.seconds
      @enemy.attack
    end

    if @enemy.turn_start_tick_count.elapsed_time == 2.seconds
      begin_turn_stage @turn_stages[:drawing_cards]
    end
  end
    
  def calc_card_positions
    @hand.each_with_index do |(id, c), i|
      c.calc_position @hand.length, i
    end

    @selected_cards.each_with_index do |(id, c), i|
      c.calc_position @selected_cards.length, i
    end
  end
    
  def calc_entity_removals
    @hand.reject! { |id, c| c.needs_removed }
    @selected_cards.reject! { |id, c| c.needs_removed }
  end
    
  def calc_keyboard_inputs
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
  end
    
  def calc_mouse_inputs
    if state.currently_dragging_card_id
      c_ref = @hand[state.currently_dragging_card_id] || @selected_cards[state.currently_dragging_card_id]
    else
      #card_under_mouse lol
      c_u_m = Geometry.find_intersect_rect inputs.mouse, get_card_rects
      c_ref = nil
    end
    
    if inputs.mouse.click
      if Geometry.intersect_rect? inputs.mouse, get_deck_rect and @turn_stage == @turn_stages[:drawing_cards]
        puts "clicked on deck"
      elsif Geometry.intersect_rect? inputs.mouse, get_pass_button_rect and @turn_stage == @turn_stages[:playing_cards]
        
        begin_turn_stage @turn_stages[:cleanup]

      end
    end
    
    if @turn_stage == @turn_stages[:playing_cards]
      if inputs.mouse.click and c_u_m
        state.currently_dragging_card_id = c_u_m.id
        c_ref = @hand[state.currently_dragging_card_id] || @selected_cards[state.currently_dragging_card_id]
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
        c_ref = @hand[state.currently_dragging_card_id] || @selected_cards[state.currently_dragging_card_id]
        c_ref.grabbed = false

        if state.click_hold_time.elapsed_time < 20 and (Geometry.distance c_ref.pos, c_ref.f_pos) < 20
          use_card c_ref
        end

        
        
        # For active hand cards, perform reordering.
        if @hand.key?(state.currently_dragging_card_id)
          
          # Exclude the dragged card from the current order.
          other_cards = @hand.values.reject { |card| card.entity_id == state.currently_dragging_card_id }
          sorted_ids = other_cards.sort_by { |card| card.pos.x }.map { |card| card.entity_id }
          
          # Calculate the center position of the dragged card.
          dragged_center = c_ref.pos[:x] + (c_ref.w / 2)
          
          # Determine where to insert the dragged card.
          new_index = sorted_ids.find_index do |card_id|
            card = @hand[card_id]
            dragged_center < (card.pos.x + (card.w / 2))
          end
          new_index ||= sorted_ids.length
          sorted_ids.insert(new_index, state.currently_dragging_card_id)
          
          # Rebuild the active hand from these sorted IDs.
          @hand = sorted_ids.map { |id| [id, @hand[id]] }.to_h
        end

        state.currently_dragging_card_id = nil
      end
    end
  end
    
  def calc_debug_inputs
      if inputs.keyboard.key_down.p and @player.potions.size > 0
        draw_card
      end
  end
  
  def begin_turn_stage new_stage
    # new stage is of the format -> @turn_stages[:stage_symbol]
    @turn_stage = new_stage 

    if new_stage == @turn_stages[:drawing_cards]
      puts "start drawing_cards stage"
      @player.my_turn = true
      @player.focus = @player.max_focus
      @turn_num += 1
      draw_card
      begin_turn_stage @turn_stages[:playing_cards]
      
    elsif new_stage == @turn_stages[:playing_cards]
      puts "start playing_cards stage"

    elsif new_stage == @turn_stages[:cleanup]
      puts "start cleanup stage"
      @player.my_turn = false
      unselect_cards
      begin_turn_stage @turn_stages[:enemy_turn]

    elsif new_stage == @turn_stages[:enemy_turn]
      @enemy.turn_start_tick_count = Kernel.tick_count
      @enemy.attacked = false
    end
  end
  
  def gen_new_card id = nil, to_deck = true
    all_ids = $pids.keys + $iids.keys

    if id == nil
      #id = all_ids.sample
      id = $iids.keys.sample
      while id == "i001"
        #id = all_ids.sample
        id = $iids.keys.sample
      end
    end
  
    name = "ERROR: NO NAME SET"
    fc = 0
    img = nil

    if potion? id
      name = $pids[id].name
      fc = $pids[id].fc
      img = $pids[id].path
      pow = $pids[id].pow
    else
      name = $iids[id].name
      img = $iids[id].path
    end

    new_ent_id = get_rand_id
    new_card = Card.new(id, new_ent_id, name, fc, img, pow)

    new_card
  end
  
    
  def draw_card
    card = @player.potions.draw
    @hand[card.entity_id] = card
  end
  
  def potions_in_hand
    n = 0
    @hand.each do |id, c|
      n += 1 if potion?(c.id)
    end
    n
  end
  
  def ingredients_in_hand
    n = 0
    @hand.each do |id, c|
      n += 1 if not potion?(c.id)
    end
    n
  end
  
  def actions_available?
    return true if ( @player.focus > 0 and potions_in_hand >= 1 ) or ( ingredients_in_hand >= 3 ) else false
  end
  
  def use_card card
    # If card clicked is a potion and not an ingredient
    if potion? card.id
      potion_info = $pids[card.id]

      #Handle deducting potion throwing focus cost
      if @player.focus >= potion_info.fc
        @player.focus -= potion_info.fc

        @player.potions.discard card
        @hand.delete card.entity_id
        # move_card card, @discards, @hand
      
        ###
        # POTION CARD BEHAVIOR HERE
        ###
        damage_trait = potion_info.traits.find { |h| h.key?($traits[:damage]) }&.[]( $traits[:damage] )
        healing_trait = potion_info.traits.find { |h| h.key?($traits[:healing]) }&.[]( $traits[:healing] )

        if damage_trait
          puts "THIS POTION DOES DAMAGE"
          @enemy.hp -= damage_trait
          status_label((grid.w / 2), (grid.h - 250), "#{damage_trait}", 255, 165, 0, 80)

          if @enemy.hp <= 0
            puts "ENEMY DIED"
          end

        elsif healing_trait
          puts "THIS POTION DOES HEALING"
          @player.hp += healing_trait
          status_label(80, (grid.h - 275), "#{damage_trait}", 0, 255, 0, 80)
          

          if @player.hp >= @player.max_hp
            @player.hp = @player.max_hp
          end
        end

        puts actions_available?
        if not actions_available?
          begin_turn_stage @turn_stages[:cleanup]
        end
      end
    else
      ###
      # INGREDIENT CARD BEHAVIOR HERE
      ###
      
      toggle_card_selected card

      @matching_potion = check_selected_cards_for_potion

    end
  end
  
  def move_card c, to, from = nil

    if to == @hand && @hand.length == @max_hand_size
      puts "ERROR: Max Hand Size Reached"
      return
    end

    to[c.entity_id] = c
    from.delete c.entity_id if from

    #if to == @hand and from == @deck
    #   c.pos.x = 20
    #   c.pos.y = 20
# 
    # elsif to == @deck and from == @hand
    #   c.pos.x = grid.w / 2
    #   c.pos.y = 20
# 
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
  
  def potion? cid
    cid[0] == "p"
  end
  
  def get_card_rects
    card_rects = []

    # Include all active hand cards
    @hand.each do |id, card|
      card_rects << card.rect
    end
    # Also include all selected cards
    @selected_cards.each do |id, card|
      card_rects << card.rect
    end

    card_rects
  end
  

  #FIXME: Needs refactored to check for all cards instanced into the game not just cards in @hand
  def get_rand_id
    new_id = Numeric.rand(0..999)

    
    while @hand.keys.include? new_id
      new_id = Numeric.rand(0..999)
    end

    return new_id
  end
  
  def get_deck_rect
    {
      x: 20,
      y: 20,
      w: 160,
      h: 160,
    }
  end
  
  def get_pass_button_rect
    {
      x: 20,
      y: grid.h - 50 - (60 / 2),
      w: 160,
      h: 60,
    }
  end
  
  def begin_combat
    puts "start begin_combat"
    
    @turn_num = 0
    3.times do
      draw_card # selected_draw_pile: "bottles"
    end

    begin_turn_stage @turn_stages[:drawing_cards]
    begin_turn_stage @turn_stages[:playing_cards]

    puts "end begin_combat"
  end
  
  def reset_deck
    @deck.reshuffle
  end
  
  def toggle_card_selected c
    if !c.selected
      move_card c, @selected_cards, @hand
    else
      move_card c, @hand, @selected_cards
    end
  end

  def unselect_cards
    @selected_cards.each do |id, c|
      toggle_card_selected c
    end
  end
  
  # Helper method: builds a frequency hash for an array
  def ingredient_counts ingredients
    ingredients.each_with_object(Hash.new(0)) do |ingredient, counts|
      counts[ingredient] += 1
    end
  end
  
  # Call this method (for example, after adding a new ingredient card)
  def check_selected_cards_for_potion
    # Extract the id's from all currently selected ingredient cards.
    selected_ids = @selected_cards.values.map &:id

    # Build a frequency hash of selected ingredient IDs.
    selected_counts = ingredient_counts selected_ids

    matching_potion = nil

    # Iterate through each potion definition in $pids.
    $pids.each do |potion_id, potion|
      # Build a frequency hash for the potion's ingredient list.
      required_counts = ingredient_counts potion[:ingredients]
      
      # Check if the counts (and thus the ingredients including repeats) match exactly.
      if selected_counts == required_counts
        puts "Matching potion found: #{potion[:name]}"
        matching_potion = { id: potion_id, data: potion }
        break  # Exit once a match is found, or remove break if you want to find all matches.
      end
    end

    unless matching_potion
      puts "No matching potion for selected ingredients: #{selected_ids}"
    end

    matching_potion
  end

end # END OF CLASS