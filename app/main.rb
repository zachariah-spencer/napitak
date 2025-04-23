def tick args
  $game ||= Game.new
  $game.args ||= args

  $game.tick
end


class Card
  attr_accessor :grabbed, :needs_removed, :pos, :f_pos, :entity_id, :w, :id, :fw, :fh, :selected, :name, :fc, :img, :padding, :pow

  def initialize id, entity_id, name, fc, img, pow
    @id = id
    @name = name
    @fc = fc

    @entity_id = entity_id

    @w = 160
    @h = 160
    @fw = 160
    @fh = 160

    @padding = -60.0

    @pos = {
      x: 0,
      y: 20,
    }
    @f_pos = {
      x: 0,
      y: 20,
    }

    @angle = 100
    @f_angle = 0

    @card_back_img = "sprites/card-back-purple.png"
    @img = img
    @pow = pow
    @card_composite_sprite_ref = :"card_composite_#{entity_id}"
    
    @r = Numeric.rand(100..200)
    @g = Numeric.rand(50..100)
    @b = Numeric.rand(100..200)

    @grabbed = false
    @selected = false
    @needs_removed = false
    calc_render_target GTK.args
  end

  def calc_position num_cards, index
    x_s = ( GTK.args.grid.w / 2) - ( num_cards * ( ( @w + @padding ) / 2 ) )
    if !@grabbed

      @f_pos.x = x_s + (index * (@w + @padding))

      if !@selected
      # slight offset to x position if cards are "fanned" because the angling makes them look off-center otherwise
      @f_pos.x = x_s + (index * (@w + @padding)) - 20
        
        
        
        max_angle = -15.0  # Maximum rotation in degrees for the extreme cards
        max_y = 30
        center_index = (num_cards - 1) / 2.0
        relative_index = index - center_index
        normalized_distance = (index - center_index).abs / center_index

        if num_cards == 2
          @f_angle = (relative_index / center_index) * max_angle
          @f_pos.y = max_y
        elsif num_cards == 3
          @f_angle = (relative_index / center_index) * 0.75 * max_angle
          @f_pos.y = max_y * ( 1 - ( 1 * (normalized_distance)**2 )) + 25
        elsif num_cards == 4
          @f_angle = (relative_index / center_index) * max_angle
          @f_pos.y = max_y * ( 1 - ( 1.5 * (normalized_distance)**2 )) + 50

        elsif num_cards > 1
          # Calculate the card's rotation as a fraction of the maximum angle
          @f_angle = (relative_index / center_index) * max_angle
          @f_pos.y = max_y * ( 1 - ( 2 * (normalized_distance)**2 )) + ( 0.75 * (12.5 * num_cards)) # +  ( 2 * (normalized_distance)**3 ) ) )# LINEAR: ((1 - normalized_distance) * max_y)

        else
          @f_angle = 0.0
          @f_pos.y = max_y
        end


      else
        @f_pos.y = ( GTK.args.grid.h / 2 ) - ( @h / 2 )
        @f_angle = 0
      end
      @pos.x = @pos.x.lerp @f_pos.x, 0.2
      @pos.y = @pos.y.lerp @f_pos.y, 0.2

      @w = @w.lerp @fw, 0.2
      @h = @h.lerp @fh, 0.2
    else
      @f_angle = 0
    end

    @angle = @angle.lerp @f_angle, 0.2

  end

  def rect
    {
      id: @entity_id,
      x: @pos.x,
      y: @pos.y,
      w: @w,
      h: @h,
      angle: @angle,
    }
  end

  def prefab
    {
      x: @pos.x,
      y: @pos.y,
      w: @w,
      h: @h,
      angle: @angle,
      path: @card_composite_sprite_ref,
      primitive_marker: :sprite,
    }
  end

  def calc_render_target args

    # define the dimensions of the combined sprite
    # the name of the combined sprite is :card_combo
    args.outputs[@card_composite_sprite_ref].w = 160
    args.outputs[@card_composite_sprite_ref].h = 160
  
    args.outputs[@card_composite_sprite_ref].primitives << {
      x: 0,
      y: 0,
      w: 160,
      h: 160,
      angle: 0,
      r: @r,
      g: @g,
      b: @b,
      path: @card_back_img,
    }
  
    args.outputs[@card_composite_sprite_ref].primitives << {
      x: 40,
      y: 40,
      w: 80,
      h: 80,
      angle: 0,
      path: @img,
    }
  
    # add a label in the center of the render target
    args.outputs[@card_composite_sprite_ref].primitives << {
      x: 80,
      y: 135,
      text: "#{@name}",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 3,
    }
  
    if @fc > 0
      if @id[0] == "i"
        # add a label in the center of the render target
        args.outputs[@card_composite_sprite_ref].primitives << {
          x: 80,
          y: 20,
          text: "#{@fc}",
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 0,
          g: 150,
          b: 150,
          size_enum: 1,
        }
      else
        # add a label in the center of the render target
        args.outputs[@card_composite_sprite_ref].primitives << {
          x: 20,
          y: 20,
          text: "#{@fc}",
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 0,
          g: 150,
          b: 150,
          size_enum: 1,
        }

        # add a label in the center of the render target
        args.outputs[@card_composite_sprite_ref].primitives << {
          x: 140,
          y: 20,
          text: "#{@pow}",
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 255,
          g: 255,
          b: 0,
          size_enum: 1,
        }
      end
    end

    args.outputs.primitives << { 
      x: 0,
      y: 0,
      w: 160,
      h: 160,
      path: @card_composite_sprite_ref,
      primitive_marker: :sprite,
    }

  end

end


class CardTrait
  attr_accessor :id, :power

  def initialize id, power
    @id = id
    @power = power
  end

end 


class Game
  attr_gtk

  def initialize
    @potion_traits = {
      damage: 0,
      healing: 1,
    }

    @pids = {
      "p001" => {
        name: "Rock Potion",
        desc: "A basic potion that damages an enemy.",
        fc: 1,
        pow: 1,
        path: "sprites/circle/green.png",
        ingredients: [
          "i001", "i004", "i004",
        ],
        traits: [
          CardTrait.new(@potion_traits[:damage], 1),
        ],
      },

      "p002" => {
        name: "Fiery Potion",
        desc: "A potion that catches an enemy on fire.",
        fc: 2,
        pow: 3,
        path: "sprites/circle/orange.png",
        ingredients: [
          "i001", "i003", "i003",
        ],
        traits: [
          CardTrait.new(@potion_traits[:damage], 3),
        ],
      },

      "p003" => {
        name: "Ocean Potion",
        desc: "A potion that sprays water at an enemy damaging them.",
        fc: 1,
        pow: 2,
        path: "sprites/circle/blue.png",
        ingredients: [
          "i001", "i002", "i002",
        ],
        traits: [
          CardTrait.new(@potion_traits[:healing], 2),
        ],
      },

      "p004" => {
        name: "Wind Potion",
        desc: "A potion that shoots air at an enemy damaging them.",
        fc: 2,
        pow: 4,
        path: "sprites/circle/indigo.png",
        ingredients: [
          "i001", "i005", "i005",
        ],
        traits: [
          CardTrait.new(@potion_traits[:damage], 4),
        ],
      },
    }




    @iids = {
      "i001" => {
        name: "Glass Bottle",
        path: "sprites/hexagon/white.png",
      },

      "i002" => {
        name: "Water",
        path: "sprites/hexagon/blue.png",
      },

      "i003" => {
        name: "Fire",
        path: "sprites/hexagon/orange.png",
      },

      "i004" => {
        name: "Earth",
        path: "sprites/hexagon/green.png",
      },

      "i005" => {
        name: "Air",
        path: "sprites/hexagon/indigo.png",
      },
    }

    @turn_stages = {
      drawing_cards: 0,
      playing_hand: 1,
      cleanup: 2,
      enemy_turn: 3,
    }
    @players_turn = false
    @players_focus_remaining = 2
    @player_hp = 20
    @player_max_hp = 20
    @deck = {}
    @hand = {}
    @selected_cards = {}
    @discards = {}
    @matching_potion = nil
    @max_hand_size = 8
    @turn_stage = nil
    @turn_num = -1
    @status_nums = []

    @enemy = {
      turn_start_tick_count: 0,
      attacked: false,
      hp: 5,
      max_hp: 5,
      damage: 1,
      # percentage chance of the enemy using each attack is the key and the attack details itself is the value
      attacks: {
        70 => {
          name: "Attack 1",
          damage: 1,
        },
        20 => {
          name: "Attack 2",
          damage: 2,
        },
        10 => {
          name: "Attack 3",
          damage: 3,
        },
      },
    }


    10.times do
      gen_new_card "i004"
    end

    # debug_card = gen_new_card "p002"
    # move_card debug_card, @hand, @deck

    begin_combat

  end

  def tick
    calc
    render
  end

  def calc
    calc_card_positions
    calc_keyboard_inputs

    if @players_turn
      calc_mouse_inputs
    else
      calc_enemy
    end

    calc_particles
    calc_entity_removals
    calc_debug_inputs
  end

  def calc_enemy
    if @enemy.turn_start_tick_count.elapsed_time == 1.seconds
      enemy_attack
    end

    if @enemy.turn_start_tick_count.elapsed_time == 2.seconds
      begin_turn_stage @turn_stages[:drawing_cards]
    end
  end

  def status_num x:, y:, text:, r:, g:, b:;
    outputs[:stat_num].w = 300
    outputs[:stat_num].h = 300
    outputs[:stat_num] << {
      text: text,
      x: 0,
      y: 0,
      size_enum: 5,
      anchor_x: 0,
      anchor_y: 0,
      primitive_marker: :label,

      r: r,
      g: g,
      b: b,
      a: 255,
    }

    new_num = outputs[:stat_num]

    @status_nums << {
      x: x - 150,
      y: y - 150,
      w: 300,
      h: 300,
      angle: Numeric.rand(-30..30),
      path: new_num,
      primitive_marker: :sprite,
      start_tick_count: Kernel.tick_count,
      needs_removed: false,
    }
  end

  def calc_particles
    @status_nums.each do |s|
      s.y += 3.5
      #s.a -= 10
      if s.start_tick_count.elapsed_time >= 0.5.seconds
        s.needs_removed = true
      end
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
    @deck.reject! { |id, c| c.needs_removed }
    @selected_cards.reject! { |id, c| c.needs_removed }
    @status_nums.reject! { |s| s.needs_removed }

  end

  def calc_keyboard_inputs
    if @matching_potion and inputs.keyboard.key_down.space 

      c = gen_new_card @matching_potion.id
      move_card c, @hand, @deck

      @selected_cards.each do |id, c|
        move_card c, @discards, @hand
        @selected_cards.delete c.entity_id
      end

      @matching_potion = nil
    end
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
        draw_card selected_draw_pile: "deck"
        puts actions_available?
        if actions_available?
          begin_turn_stage @turn_stages[:playing_cards]
        else
          begin_turn_stage @turn_stages[:cleanup]
        end

      elsif Geometry.intersect_rect? inputs.mouse, get_bottles_rect and @turn_stage == @turn_stages[:drawing_cards]
        puts "clicked on bottles"
        draw_card selected_draw_pile: "bottles"
        if actions_available?
          begin_turn_stage @turn_stages[:playing_cards]
        else
          begin_turn_stage @turn_stages[:cleanup]
        end

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
    if inputs.keyboard.key_down.o and @hand.length > 0
      c = @hand[@hand.keys.last]
      move_card c, @deck, @hand
    end

    if inputs.keyboard.key_down.p and @deck.length > 0
      draw_card selected_draw_pile: "deck"
    end

    if inputs.keyboard.key_down.b
      draw_card selected_draw_pile: "bottles"
    end

    if inputs.keyboard.key_down.t and !@players_turn
      begin_turn_stage @turn_stages[:drawing_cards]
    end
  end

  def render
    render_layer_1 = []
    render_layer_2 = []
    render_layer_3 = []
    render_layer_4 = []

    cards ||= []
    selected_cards ||= []
    front_card = nil

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
      text: "#{@deck.keys.length}",
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

    range = 255 - 0
    x = (Kernel.tick_count * 10) % (2 * range)
    osc_val = range - (x - range).abs

    deck_highlight_border ||= {
      x: 15,
      y: 15,
      w: 170,
      h: 170,
      anchor_x: 0,
      anchor_y: 0,
      r: 255,
      g: 255,
      b: 255,
      a: osc_val,
      primitive_marker: :solid,
    }

    bottle_deck_sprite ||= {
      x: 20,
      y: 205,
      w: 160,
      h: 160,
      r: 80,
      g: 80,
      b: 80,
      primitive_marker: :solid,
    }

    bottle_deck_highlight_border ||= {
      x: 15,
      y: 200,
      w: 170,
      h: 170,
      anchor_x: 0,
      anchor_y: 0,
      r: 255,
      g: 255,
      b: 255,
      a: osc_val,
      primitive_marker: :solid,
    }

    if @turn_stage == @turn_stages[:drawing_cards]
      render_layer_2 << [deck_highlight_border, bottle_deck_highlight_border]
    end

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

    enemy_sprite ||= {
      x: grid.w / 2 - 100,
      y: grid.h - 250,
      w: 200,
      h: 200,
      r: 150,
      g: 0,
      b: 0,
      primitive_marker: :solid,
    }

    enemy_hp_label ||= {
      x: grid.w / 2,
      y: grid.h - 270,
      alignment_enum: 1,
      size_enum: 5,
      r: 150,
      g: 0,
      b: 0,
      text: "#{@enemy.hp}/#{@enemy.max_hp}",
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
      text: "#{@players_focus_remaining}",
      primitive_marker: :label,
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
      text: "#{@player_hp}/#{@player_max_hp}",
      primitive_marker: :label,
    }





    if @players_turn
      render_layer_2 << players_turn_label
    end

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
    
    @hand.each do |id, c|
      prefab = c.prefab

      if c.grabbed
        front_card = prefab
      else
        cards.append prefab
      end
    end

    @selected_cards.each { |id, c| selected_cards.append c.prefab }
    
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
      render_layer_3 << [ craftable_potion_tooltip ]
    end

    render_layer_1 << [ left_panel, enemy_sprite, enemy_hp_label, player_hp_label_header, player_hp_label, player_focus_label_header, player_focus_label, ]
    render_layer_2 << [ deck_sprite, deck_card_count_label, bottle_deck_sprite, pass_button, pass_button_label, cards, selected_cards ]
    render_layer_3 << [ front_card ]
    render_layer_4 << [ @status_nums ]
    outputs.primitives << [ background, render_layer_1, render_layer_2, render_layer_3, render_layer_4 ]
  end

  def begin_turn_stage new_stage
    # new stage is of the format -> @turn_stages[:stage_symbol]
    @turn_stage = new_stage 

    if new_stage == @turn_stages[:drawing_cards]
      puts "start drawing_cards stage"
      @players_turn = true
      @players_focus_remaining = 2
      @turn_num += 1
      
    elsif new_stage == @turn_stages[:playing_cards]
      puts "start playing_cards stage"

    elsif new_stage == @turn_stages[:cleanup]
      puts "start cleanup stage"
      @players_turn = false
      unselect_cards
      begin_turn_stage @turn_stages[:enemy_turn]

    elsif new_stage == @turn_stages[:enemy_turn]
      @enemy.turn_start_tick_count = Kernel.tick_count
      @enemy.attacked = false
    end
  end

  def enemy_attack
    attack = enemy_pick_attack
    
    status_num x: (grid.w / 2) + Numeric.rand(-50..50), y: grid.h - 160 + Numeric.rand(-50..50), text: "#{attack[:name]}", r: 255, g: 255, b: 255

    status_num x: (grid.w / 2) + Numeric.rand(-50..50), y: grid.h - 400 + Numeric.rand(-50..50), text: "#{attack[:damage]}", r: 255, g: 0, b: 0

    @player_hp -= attack[:damage]
    if @player_hp <= 0
      puts "PLAYER DIED"
    end

    @enemy.attacked = true
  end

  def enemy_pick_attack
    rand_n = Numeric.rand(0..100)
    att_probs = @enemy.attacks.keys
    attacks = @enemy[:attacks]
    attack = 0

    if rand_n >= 0 and rand_n < att_probs[0]
      attack = attacks[att_probs[0]]
    elsif rand_n  >= att_probs[0] and rand_n < ( att_probs[0] + att_probs[1] )
      attack = attacks[att_probs[1]]
    elsif rand_n >= ( att_probs[0] + att_probs[1] ) and rand_n < ( att_probs[0]+ att_probs[1] + att_probs[2] )
      attack = attacks[att_probs[2]]
    end

    attack
  end

  def gen_new_card id = nil, to_deck = true
    all_ids = @pids.keys + @iids.keys

    if id == nil
      #id = all_ids.sample
      id = @iids.keys.sample
      while id == "i001"
        #id = all_ids.sample
        id = @iids.keys.sample
      end
    end

    

    name = "ERROR: NO NAME SET"
    fc = 0
    img = nil

    if potion? id
      name = @pids[id].name
      fc = @pids[id].fc
      img = @pids[id].path
      pow = @pids[id].pow
    else
      name = @iids[id].name
      img = @iids[id].path
    end

    new_ent_id = get_rand_id
    new_card = Card.new(id, new_ent_id, name, fc, img, pow)

    if to_deck
      move_card new_card, @deck
    else
      move_card new_card, @hand
    end

    new_card
  end

  

  def draw_card selected_draw_pile:;
    if selected_draw_pile == "deck" and @deck.length > 0
      # Draw a card from deck
      c = @deck[@deck.keys.sample]
      move_card c, @hand, @deck
    elsif selected_draw_pile == "bottles"
      # Draw bottle
      c = gen_new_card "i001", false
    end
    
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
    return true if ( @players_focus_remaining > 0 and potions_in_hand >= 1 ) or ( ingredients_in_hand >= 3 ) else false
  end

  def use_card card
    # If card clicked is a potion and not an ingredient
    if potion? card.id
      potion_info = @pids[card.id]

      #Handle deducting potion throwing focus cost
      if @players_focus_remaining >= potion_info.fc
        @players_focus_remaining -= potion_info.fc

        move_card card, @discards, @hand
      
        ###
        # POTION CARD BEHAVIOR HERE
        ###
        damage_trait = potion_info.traits.detect { |t| t.id == @potion_traits[:damage] }
        healing_trait = potion_info.traits.detect { |t| t.id == @potion_traits[:healing] }
        if damage_trait
          puts "THIS POTION DOES DAMAGE"
          @enemy.hp -= damage_trait.power

          if @enemy.hp <= 0
            puts "ENEMY DIED"
          end

        elsif healing_trait
          puts "THIS POTION DOES HEALING"
          @player_hp += healing_trait.power

          if @player_hp >= @player_max_hp
            @player_hp = @player_max_hp
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
      
      if !card.selected
        move_card card, @selected_cards, @hand
      else
        move_card card, @hand, @selected_cards
      end

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

    if to == @hand and from == @deck
      c.pos.x = 20
      c.pos.y = 20

    elsif to == @deck and from == @hand
      c.pos.x = grid.w / 2
      c.pos.y = 20

    elsif to == @hand && from == nil
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

  def get_bottles_rect
    {
      x: 20,
      y: 200, 
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
    2.times do
      draw_card selected_draw_pile: "bottles"
    end

    4.times do
      draw_card selected_draw_pile: "deck"
    end

    begin_turn_stage @turn_stages[:drawing_cards]
    begin_turn_stage @turn_stages[:playing_cards]

    puts "end begin_combat"
  end

  def reset_deck
    @discards.each do |id, c|
      move_card c, @deck, @discards
    end
  end

  def unselect_cards
    @selected_cards.each do |id, c|
      move_card c, @hand, @selected_cards
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

    # Iterate through each potion definition in @pids.
    @pids.each do |potion_id, potion|
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


end





# reset is a top-level function that DR is aware of
# and will be invoked before GTK.reset occurs.
def reset args
  # A new rng will be used GTK.reset is invoked
  GTK.set_rng (Time.now.to_f * 100).to_i
end
GTK.reset_next_tick