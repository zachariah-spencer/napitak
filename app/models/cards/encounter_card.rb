# frozen_string_literal: true

class EncounterCard < Card
  attr :f_pos, :selected, :fw

  def initialize(id)
    super(
      id,
      GameUtils.new_id?,
      $encounters[id].name,
      0,
      $encounters[id].path
    )
    @selected = nil
  end

  def tick
    calc_hover
    calc_click
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
      @selected = { id: @id, data: $encounters[@id] }
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
      @fw = 250
      @fh = 250
    else
      @fw = 225
      @fh = 225
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
      x: 40,
      y: 40,
      w: 80,
      h: 80,
      angle: 0,
      path: @img
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
      size_enum: -3
    }

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
