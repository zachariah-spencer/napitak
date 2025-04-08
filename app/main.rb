def tick args
  $game ||= Game.new
  $game.args ||= args

  $game.tick

end





class Card
  attr_accessor :grabbed, :needs_removed, :pos, :f_pos, :entity_id, :w, :id, :fw, :fh, :selected

  def initialize id, entity_id
    @id = id

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

    @path = "sprites/card-back-purple.png"
    
    @r = Numeric.rand(200..255)
    @g = Numeric.rand(0..255)
    @b = Numeric.rand(200..255)

    @primitive_marker = :solid

    @grabbed = false
    @selected = false
    @needs_removed = false
  end

  def calc_position num_cards, index
    x_s = ( GTK.args.grid.w / 2 ) - ( num_cards * ( (@w + @padding) / 2) )

    if !@grabbed
      @f_pos.x = x_s + (index * (@w + @padding))
      #c.f_angle = add code to handle index-based angling here
      
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
      r: @r,
      g: @g,
      b: @b,
      angle: @angle,
      path: @path,
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
    @selected_cards = []

#    5.times do
#      gen_new_card
#    end
    gen_new_card "i001"
    gen_new_card "i002"
    gen_new_card "i003"
    gen_new_card "i003"
    gen_new_card "i004"
    gen_new_card "i005"


  end

  def tick
    calc
    render
  end

  def calc
    calc_card_positions

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
  end

  def calc_entity_removals
    @hand.reject! {|id, c| c.needs_removed }
  end

  def calc_mouse_inputs
    if state.currently_dragging_card_id
      c_ref = @hand[state.currently_dragging_card_id]
    else
      #card_under_mouse lol
      c_u_m = Geometry.find_intersect_rect inputs.mouse, get_card_rects
      c_ref = nil
    end

    if inputs.mouse.click and c_u_m
      state.currently_dragging_card_id = c_u_m.id
      c_ref = @hand[state.currently_dragging_card_id]
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

      
      c_ref.grabbed = false

      # Exclude the dragged card from the sorted order
      other_cards = @hand.values.reject { |card| card.entity_id == state.currently_dragging_card_id }
      sorted_ids = other_cards.sort_by { |card| card.pos.x }.map { |card| card.entity_id }

      # Calculate the center of the dragged card
      dragged_center = c_ref.pos[:x] + (c_ref.w / 2)

      # Find the index where the dragged card should be inserted
      new_index = sorted_ids.find_index do |card_id|
        card = @hand[card_id]
        # Compare centers to decide insertion point
        dragged_center < (card.pos.x + (card.w / 2))
      end
      # If none found, insert at the end
      new_index ||= sorted_ids.length

      # Insert the dragged card id at the computed index
      sorted_ids.insert(new_index, state.currently_dragging_card_id)

      # Rebuild @hand hash based on new sorted order
      @hand = sorted_ids.map { |id| [id, @hand[id]] }.to_h

      state.currently_dragging_card_id = nil
    end

  end

  def calc_debug_inputs
    if inputs.keyboard.key_down.o and @hand.length > 0
      @hand.delete @hand.keys.last
    end

    if inputs.keyboard.key_down.p
      gen_new_card
    end

    if inputs.keyboard.key_down.t and !@players_turn
      begin_turn
    end
  end

  def render
    back_render_layer = []
    front_render_layer = []

    background ||= {
      x: 0,
      y: 0,
      w: args.grid.w,
      h: args.grid.h,
      r: 150,
      g: 150,
      b: 250,
      primitive_marker: :solid,
    }

    hand ||= []
    front_card = nil

    # REFACTOR TO HAND
    @hand.each do |id, c|
      prefab = c.prefab

      if c.grabbed
        front_card = prefab
      else
        hand.append prefab
      end
    end

    

    
    back_render_layer << [ background, hand ]
    front_render_layer << [ front_card ]

    outputs.primitives << [ back_render_layer, front_render_layer ]
  end

  # REFACTOR TO HAND
  def get_card_rects
    card_rects = []
    @hand.each do |id, c|
      card_rects << c.rect
    end

    return card_rects
  end

  def begin_turn
    @players_turn = true
    @players_focus_remaining = 2
    gen_new_card
    
  end

  def gen_new_card id = nil
    #HOW TO ADD A NEW CARD TO HAND (USE @deck FOR DECK)

    if id == nil
      all_ids = @pids.keys + @iids.keys
      id = all_ids.sample
    end

    new_ent_id = get_rand_id
    @hand[new_ent_id] = Card.new(id, new_ent_id)
  end

  def get_rand_id
    new_id = Numeric.rand(0..999)

    
    while @hand.keys.include? new_id
      new_id = Numeric.rand(0..999)
    end

    return new_id
  end

  def use_card card
    # If card clicked is a potion and not an ingredient
    if card.id[0] == "p"

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
    elsif card.id[0] == "i"
      ###
      # INGREDIENT CARD BEHAVIOR HERE
      ###

      puts "INGREDIENT CLICKED"
      
      if !card.selected
        card.selected = true
        card.fw = 200
        card.fh = 200
        @selected_cards.append card
      else
        card.selected = false
        card.fw = 160
        card.fh = 160
        @selected_cards.delete card
      end

      puts check_selected_cards_for_potion

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
    selected_ids = @selected_cards.map &:id

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