# frozen_string_literal: true

class EncounterCard < Card
  attr :f_pos, :selected, :fw

  def initialize(id)
    super(id, GameUtils.new_id?, $ENCOUNTERS[id].name, 0, $ENCOUNTERS[id].path)
    @selected = nil
  end

  def tick
    if !$game.input_locked
      calc_hover
      calc_click
    else
      @hovered = false
    end
    calc_position(-1, -1)
  end

  def calc_hover
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
  end

  def calc_click
    if (
         Geometry.intersect_rect?(GTK.args.inputs.mouse, rect) and
           GTK.args.inputs.mouse.click
       )
      puts "#{@entity_id} || #{@name} : was clicked"
      @selected = { id: @id, data: $ENCOUNTERS[@id] }
    end
  end

  def pop_clicked
    encounter = @selected
    @selected = nil
    encounter
  end

  def prefab
    {
      x: @pos.x,
      y: @pos.y,
      w: @w,
      h: @h,
      angle: @angle,
      path: @card_composite_sprite_ref,
      primitive_marker: :sprite
    }
  end

  def rect
    { id: @entity_id, x: @pos.x, y: @pos.y, w: @w, h: @h, angle: @angle }
  end

  def calc_position(num_cards, index)
    if @hovered
      @fw = 230
      @fh = 230
    else
      @fw = 190
      @fh = 190
      @f_pos.y =
        @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
      @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.005) * 2
    end

    super
  end

  def calc_render_target(args)
    # define the dimensions of the combined sprite
    # the name of the combined sprite is :card_combo
    args.outputs[@card_composite_sprite_ref].w = @w
    args.outputs[@card_composite_sprite_ref].h = @h

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      angle: 0,
      r: @r,
      g: @g,
      b: @b,
      path: @card_back_img
    }

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: 50,
      y: 50,
      w: 60,
      h: 60,
      angle: 0,
      path: @img
    }

    # add a label in the center of the render target
    # args.outputs[@card_composite_sprite_ref].primitives << {
    #   x: 80,
    #   y: 135,
    #   text: "#{@name}",
    #   anchor_x: 0.5,
    #   anchor_y: 0.5,
    #   r: 255,
    #   g: 255,
    #   b: 255,
    #   size_px: 20
    # }

    parsed_name = String.wrapped_lines @name, 15
    args.outputs[
      @card_composite_sprite_ref
    ].primitives << parsed_name.map_with_index do |s, i|
      {
        x: 80,
        y: 128,
        text: "#{s}",
        anchor_x: 0.5,
        anchor_y: i,
        r: 255,
        g: 255,
        b: 255,
        font: "fonts/eaglelake.ttf",
        size_px: 20
      }
    end

    args.outputs.primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      path: @card_composite_sprite_ref,
      primitive_marker: :sprite
    }
  end
end
