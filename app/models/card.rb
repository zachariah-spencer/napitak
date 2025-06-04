class Card
  attr_accessor :grabbed,
                :needs_removed,
                :pos,
                :f_pos,
                :entity_id,
                :w,
                :id,
                :fw,
                :fh,
                :selected,
                :name,
                :fc,
                :img,
                :padding,
                :max_uses,
                :activation_time,
                :uses_left

  def initialize(id, entity_id, name, fc, img, max_uses = 0)
    @id = id
    @name = name
    @fc = fc

    @entity_id = entity_id
    @floating_seed = Numeric.rand(0.0..100.0)

    @w = 160
    @h = 160
    @fw = 160
    @fh = 160

    @padding = -60.0

    @pos = { x: 0, y: 20 }
    @f_pos = { x: 0, y: 20 }

    @angle = 0
    @f_angle = 0

    @card_back_img = "sprites/card-back-purple.png"
    @img = img
    @max_uses = max_uses
    @uses_left = max_uses
    @card_composite_sprite_ref = :"card_composite_#{entity_id}"

    @r = 150 # Numeric.rand(100..200)
    @g = 150 # Numeric.rand(50..100)
    @b = 150 # Numeric.rand(100..200)

    @grabbed = false
    @selected = false
    @needs_removed = false
    @activation_time = 0.0
    calc_render_target GTK.args
  end

  def calc_position(num_cards, index)
  end

  def rect
    { id: @entity_id, x: @pos.x, y: @pos.y, w: @w, h: @h, angle: @angle }
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

  def update_sprite()
    calc_render_target(GTK.args)
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
      size_enum: 3
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
          size_enum: 1
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
          size_enum: 1
        }

        # add a label in the center of the render target
        args.outputs[@card_composite_sprite_ref].primitives << {
          x: 122.5,
          y: 20,
          text: "#{@uses_left}/#{@max_uses}",
          anchor_x: 0.5,
          anchor_y: 0.5,
          alignment_enum: 2,
          r: 255,
          g: 255,
          b: 0,
          size_enum: 1
        }
      end
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
