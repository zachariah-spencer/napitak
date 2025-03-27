def tick args

  $game ||= Game.new
  $game.args ||= args

  $game.tick

end

class Game
  attr_gtk

  def initialize
    @c_w = 100
    @c_h = 150
    @card_offset = 20
    @cards = {}

    5.times_with_index do |id|
      @cards[id] = new_random_card id
    end
  end

  def tick
    x_c = ( grid.w / 2 ) - ( @cards.length * ( (@c_w + @card_offset) / 2) )

    @cards.each_with_index do |(id, c), i|
      if !c.grabbed
        c.f_pos.x = x_c + (i * (@c_w + @card_offset))
        c.pos.x = c.pos.x.lerp c.f_pos.x, 0.2
        c.pos.y = c.pos.y.lerp c.f_pos.y, 0.2
      end
    end

    if inputs.keyboard.key_down.o
      @cards.delete @cards.keys.last
    end

    if inputs.keyboard.key_down.p
      new_id = (@cards.keys.last + 1)
      @cards[new_id] = new_random_card new_id
    end

    if state.currently_dragging_card_id
      c_ref = @cards[state.currently_dragging_card_id]
    else
      #card_under_mouse lol
      c_u_m = Geometry.find_intersect_rect inputs.mouse, get_card_rects
      c_ref = nil
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
    elsif
      inputs.mouse.held and state.currently_dragging_card_id
      c_ref.pos.x = inputs.mouse.x - state.mouse_point_inside_square.x
      c_ref.pos.y = inputs.mouse.y - state.mouse_point_inside_square.y
    elsif inputs.mouse.up

      

      c_ref.grabbed = false
      state.currently_dragging_card_id = nil
    end

    

    render
  end

  def render

    card_prefabs ||= []
    @cards.each do |id, c|
      card_prefab = prefab_card c

      card_prefabs.append card_prefab
    end

    outputs.primitives << 
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
    
  end

  def new_random_card id
    {
      id: id,
      pos: 
      {
        x: 0,
        y: 20,
      },
      f_pos:
      {
        x: 0,
        y: 20,
      },
      center: 
      {
        x: @c_w / 2,
        y: @c_h / 2,
      },
      w: @c_w,
      h: @c_h,
      r: Numeric.rand(0..255),
      g: Numeric.rand(0..255),
      b: Numeric.rand(0..255),
      primitive_marker: :solid,
      grabbed: false,
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
      }
    end

    return card_rects
  end

end


# reset is a top-level function that DR is aware of
# and will be invoked before GTK.reset occurs.
def reset args
  # A new rng will be used GTK.reset is invoked
  GTK.set_rng (Time.now.to_f * 100).to_i
end

GTK.reset_next_tick