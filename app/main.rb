def tick args
  $game ||= Game.new
  $game.args ||= args

  $game.tick
end


class Card
  attr_accessor :grabbed, :needs_removed, :pos, :f_pos, :entity_id, :w, :id, :fw, :fh, :selected, :name, :fc, :img

  def initialize id, entity_id, name, fc, img
    @id = id
    @name = name
    @fc = fc

    @entity_id = entity_id

    @w = 160
    @h = 160
    @fw = 160
    @fh = 160

    @padding = 20

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
    x_s = ( GTK.args.grid.w / 2 ) - ( num_cards * ( ( @w + @padding ) / 2 ) )

    if !@grabbed

      @f_pos.x = x_s + (index * (@w + @padding))

      if !@selected
        @f_pos.y = 20
        #c.f_angle = add code to handle index-based angling here
      else
        @f_pos.y = ( GTK.args.grid.h / 2 ) - ( @h / 2 )
      end


      @angle = @angle.lerp @f_angle, 0.2

      @pos.x = @pos.x.lerp @f_pos.x, 0.2
      @pos.y = @pos.y.lerp @f_pos.y, 0.2

      @w = @w.lerp @fw, 0.2
      @h = @h.lerp @fh, 0.2
    end

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
      # add a label in the center of the render target
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: 80,
        y: 20,
        text: "#{@fc}",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255,
        size_enum: 1,
      }
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





class Game
  attr_gtk

  def initialize
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
        path: "sprites/hexagon/blue.png",
      },
    }

    @players_turn = true
    @players_focus_remaining = 2
    @deck = {}
    @hand = {}
    @selected_cards = {}
    @matching_potion = nil

    8.times do
      gen_new_card
    end


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
    end

    calc_entity_removals

    calc_debug_inputs
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

  end

  def calc_keyboard_inputs
    if @matching_potion and inputs.keyboard.key_down.space 

      c = gen_new_card @matching_potion.id
      move_card c, @hand, @deck

      @selected_cards.each do |id, c|
        @hand.delete c.entity_id
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


      if state.click_hold_time.elapsed_time < 20 and (Geometry.distance c_ref.pos, c_ref.f_pos) < 20
        use_card c_ref
      end

      # Re-fetch the card from either group.
      c_ref = @hand[state.currently_dragging_card_id] || @selected_cards[state.currently_dragging_card_id]
      c_ref.grabbed = false
      
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

  def calc_debug_inputs
    if inputs.keyboard.key_down.o and @hand.length > 0
      c = @hand[@hand.keys.last]
      move_card c, @deck, @hand
    end

    if inputs.keyboard.key_down.p and @deck.length > 0
      c = @deck[@deck.keys.sample]
      move_card c, @hand, @deck
    end

    if inputs.keyboard.key_down.b
      c = gen_new_card "i001"
      move_card c, @hand, @deck
    end

    if inputs.keyboard.key_down.t and !@players_turn
      begin_turn
    end
  end

  def render
    back_render_layer = []
    mid_render_layer = []
    front_render_layer = []

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

    


    cards ||= []
    selected_cards ||= []
    front_card = nil
    
    # REFACTOR TO HAND
    @hand.each do |id, c|
      prefab = c.prefab

      if c.grabbed
        front_card = prefab
      else
        cards.append prefab
      end
    end

    @selected_cards.each { |id, c| selected_cards.append c.prefab }
    


    
    back_render_layer << [ background, cards ]
    mid_render_layer << [ selected_cards ]
    front_render_layer << [ front_card ]
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
      

      front_render_layer << [ craftable_potion_tooltip ]
    end



    outputs.primitives << [ back_render_layer, mid_render_layer, front_render_layer ]

  end

  # REFACTOR TO HAND
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

  def begin_turn
    @players_turn = true
    @players_focus_remaining = 2
    gen_new_card
  end

  def gen_new_card id = nil
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
    else
      name = @iids[id].name
      img = @iids[id].path
    end

    new_ent_id = get_rand_id
    new_card = Card.new(id, new_ent_id, name, fc, img)
    move_card new_card, @deck

    new_card
  end

  def draw_card
    
  end

  def move_card c, to, from = nil
    to[c.entity_id] = c
    from.delete c.entity_id if from

    if from == @deck
      c.pos.x = 0
      c.pos.y = 0
    elsif from == @hand
      c.pos.x = grid.w / 2
      c.pos.y = 20

    end

  end

  def get_rand_id
    new_id = Numeric.rand(0..999)

    
    while @hand.keys.include? new_id
      new_id = Numeric.rand(0..999)
    end

    return new_id
  end

  def potion? cid
    cid[0] == "p"
  end

  def use_card card
    # If card clicked is a potion and not an ingredient
    if potion? card.id

      #Handle deducting potion throwing focus cost
      if @players_focus_remaining >= @pids[card.id].fc
    
        @players_focus_remaining -= @pids[card.id].fc
    
        if @players_focus_remaining <= 0 or @hand.length <= 1
          @players_turn = false
        end
      
        ###
        # POTION CARD BEHAVIOR HERE
        ###

        card.needs_removed = true
      end
    else
      ###
      # INGREDIENT CARD BEHAVIOR HERE
      ###
      
      if !card.selected
        card.selected = true
        card.fw = 250
        card.fh = 250
        card.grabbed = false
        
        @selected_cards[card.entity_id] = card
        @hand.delete card.entity_id
      else
        card.selected = false
        card.fw = 160
        card.fh = 160
        card.grabbed = false

        @hand[card.entity_id] = card
        @selected_cards.delete card.entity_id
      end

      @matching_potion = check_selected_cards_for_potion

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