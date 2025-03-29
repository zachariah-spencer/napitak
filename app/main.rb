def tick args

  $game ||= Game.new
  $game.args ||= args

  $game.tick

end

class Game
  attr_gtk

  def initialize
    @players_turn = true
    @players_focus_remaining = 2
    @c_w = 100
    @c_h = 150
    @card_offset = 20
    @cards = {}

    5.times_with_index do |id|
      @cards[id] = new_random_card id
    end

    @player
  end

  def tick
    calc
    render
  end

  def calc
    calc_card_fixed_positions

    if @players_turn
      calc_mouse_inputs
    end

    calc_entity_removals

    calc_debug_inputs
  end

  def calc_entity_removals
    @cards.reject! {|id, c| c.needs_removed }
  end

  def calc_card_fixed_positions
    x_s = ( grid.w / 2 ) - ( @cards.length * ( (@c_w + @card_offset) / 2) )

    @cards.each_with_index do |(id, c), i|
      if !c.grabbed
        c.f_pos.x = x_s + (i * (@c_w + @card_offset))
        #c.f_ang = add code to handle index-based angling here
        
        c.angle = c.angle.lerp c.f_ang, 0.2
        c.pos.x = c.pos.x.lerp c.f_pos.x, 0.2
        c.pos.y = c.pos.y.lerp c.f_pos.y, 0.2
      end
    end
  end

  def calc_mouse_inputs
    if state.currently_dragging_card_id
      c_ref = @cards[state.currently_dragging_card_id]
    else
      #card_under_mouse lol
      c_u_m = Geometry.find_intersect_rect inputs.mouse, get_card_rects
      c_ref = nil
    end

    if inputs.mouse.click
      puts @cards.keys
    end


    if inputs.mouse.click and c_u_m
      state.currently_dragging_card_id = c_u_m.id
      c_ref = @cards[state.currently_dragging_card_id]
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
        play_card c_ref
      end

      
      c_ref.grabbed = false

      # Exclude the dragged card from the sorted order
      other_cards = @cards.values.reject { |card| card[:id] == state.currently_dragging_card_id }
      sorted_ids = other_cards.sort_by { |card| card[:pos][:x] }.map { |card| card[:id] }

      # Calculate the center of the dragged card
      dragged_center = c_ref.pos[:x] + (@c_w / 2)

      # Find the index where the dragged card should be inserted
      new_index = sorted_ids.find_index do |card_id|
        card = @cards[card_id]
        # Compare centers to decide insertion point
        dragged_center < (card[:pos][:x] + (@c_w / 2))
      end
      # If none found, insert at the end
      new_index ||= sorted_ids.length

      # Insert the dragged card id at the computed index
      sorted_ids.insert(new_index, state.currently_dragging_card_id)

      # Rebuild @cards hash based on new sorted order
      @cards = sorted_ids.map { |id| [id, @cards[id]] }.to_h

      state.currently_dragging_card_id = nil
    end

  end

  def calc_debug_inputs
    if inputs.keyboard.key_down.o and @cards.length > 0
      @cards.delete @cards.keys.last
    end

    if inputs.keyboard.key_down.p
      
      new_id = nil

      if @cards.length > 0
        new_id = (@cards.keys.last + 1)
      else
        new_id = 0
      end


      @cards[new_id] = new_random_card new_id
    end

    if inputs.keyboard.key_down.t and !@players_turn
      @players_turn = true
      @players_focus_remaining = 2
    end
  end

  def render
    back_render_layer = []
    front_render_layer = []

    card_prefabs ||= []
    @cards.each do |id, c|
      card_prefab = prefab_card c

      if c.grabbed
        front_render_layer << card_prefab
      else
        card_prefabs.append card_prefab
      end

      
    end
    
    back_render_layer << 
    [
      {
        x: 0,
        y: 0,
        w: args.grid.w,
        h: args.grid.h,
        r: 20,
        g: 20,
        b: 60,
        primitive_marker: :solid,
      },

      card_prefabs
    ]

    outputs.primitives << [back_render_layer, front_render_layer]
    
  end

  def new_random_card id
    {
      id: id,
      pos: 
      {
        x: 0,
        y: 20,
      },
      angle: 100,
      f_pos:
      {
        x: 0,
        y: 20,
      },
      f_ang: 0,
      w: @c_w,
      h: @c_h,
      r: Numeric.rand(0..255),
      g: Numeric.rand(0..255),
      b: Numeric.rand(0..255),
      primitive_marker: :solid,
      grabbed: false,
      needs_removed: false,
      type_id: 0,
      focus_cost: 1,
    }
  end

  def prefab_card card;
    {
      x: card.pos.x,
      y: card.pos.y,
      w: card.w,
      h: card.h,
      r: card.r,
      g: card.g,
      b: card.b,
      angle: card.angle,
      primitive_marker: :solid,
    }
  end

  def get_card_rects
    card_rects = []
    @cards.each do |id, c|
      card_rects << {
        id: c.id,
        x: c.pos.x,
        y: c.pos.y,
        w: c.w,
        h: c.h,
        angle: c.angle,
      }
    end

    return card_rects
  end

end

def play_card card
  if @players_focus_remaining >= card.focus_cost

    @players_focus_remaining -= card.focus_cost

    if @players_focus_remaining <= 0
      @players_turn = false
    end
  
    #
    # CARD BEHAVIOR HERE
    #
  
    card.needs_removed = true
  end

  puts "Focus Remaining: #{@players_focus_remaining}"
  puts "Card Costed This Much Focus to Play: #{card.focus_cost}"
  
end


# reset is a top-level function that DR is aware of
# and will be invoked before GTK.reset occurs.
def reset args
  # A new rng will be used GTK.reset is invoked
  GTK.set_rng (Time.now.to_f * 100).to_i
end

GTK.reset_next_tick