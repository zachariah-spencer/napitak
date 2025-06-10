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
                :uses_left,
                :hovered

  def initialize(id, entity_id, name, fc, img, max_uses = 0, desc = "", potencies = {})
    @id = id
    @name = name
    @fc = fc
    @desc = desc
    @potencies = potencies

    @entity_id = entity_id
    @floating_seed = Numeric.rand(0.0..100.0)

    @w = 160
    @h = 160
    @fw = 160
    @fh = 160
    @ttw = 1000
    @tth = 1000

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
    @card_composite_tooltip_ref = :"card_composite_tooltip_#{entity_id}"

    @r = 150 # Numeric.rand(100..200)
    @g = 150 # Numeric.rand(50..100)
    @b = 150 # Numeric.rand(100..200)

    @grabbed = false
    @selected = false
    @hovered = false
    @tt_a = 0
    @tt_f_a = 0
    @needs_removed = false
    @activation_time = 0.0
    calc_render_target GTK.args
  end

  def tick()
    calc_hover
    calc_render_target(GTK.args)
  end

  def calc_position(num_cards, index)
  end

  def rect
    { id: @entity_id, x: @pos.x, y: @pos.y, w: @w, h: @h, angle: @angle }
  end

  def calc_hover
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)

    if @hovered
      @tt_f_a = 255
    else
      @tt_f_a = 0
    end
  end

  def prefab
    card_sprite = {
      x: @pos.x,
      y: @pos.y,
      w: @w,
      h: @h,
      angle: @angle,
      path: @card_composite_sprite_ref,
      primitive_marker: :sprite
    }
    tt_sprite = {
      x: @pos.x - (@w / 2),
      y: @pos.y + (@h + 80) - (@h / 2),
      w: @w * 2,
      h: @h * 2,
      a: @tt_a,
      angle: 0,
      path: @card_composite_tooltip_ref,
      primitive_marker: :sprite
    }
    return [ card_sprite, tt_sprite ]
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

        if @hovered
          render_tooltip(args)
        end

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

  def render_tooltip(args)

    args.outputs[@card_composite_tooltip_ref].w = @w * 2
    args.outputs[@card_composite_tooltip_ref].h = @h * 2
    # add a label in the center of the render target
    args.outputs[@card_composite_tooltip_ref].primitives << {
      x: 20,
      y: 20,
      w: @w * 2,
      h: @h * 2,
      r: 20,
      g: 20,
      b: 40,
      a: 180,
      primitive_marker: :solid,
    }
    parsed_name = String.wrapped_lines @name, 15
    args.outputs[@card_composite_tooltip_ref].primitives << parsed_name.map_with_index do |s, i| 
      {
      x: 165,
      y: 280,
      text: "#{s}",
      anchor_x: 0.5,
      anchor_y: i,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 10
      }
    end

    parsed_description = String.wrapped_lines @desc, 25
    # add a label in the center of the render target
    args.outputs[@card_composite_tooltip_ref].primitives << parsed_description.map_with_index do |s, i| 
      {
      x: 165,
      y: 250,
      text: "#{s}",
      anchor_x: 0.5,
      anchor_y: i,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 1
      }
    end

    args.outputs[@card_composite_tooltip_ref].primitives << 
      {
      x: 55,
      y: 65,
      text: "Focus",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 1
      }

    args.outputs[@card_composite_tooltip_ref].primitives << 
      {
      x: 55,
      y: 35,
      text: "#{@fc}",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 1
      }

      args.outputs[@card_composite_tooltip_ref].primitives << 
      {
      x: 270,
      y: 65,
      text: "Potencies",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 1
      }

      @potencies.each do |trait_id, potency_val|
        color = trait_color?(trait_id)

        args.outputs[@card_composite_tooltip_ref].primitives << 
        {
        x: 270,
        y: 35,
        text: "#{potency_val.to_s}",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: color.r,
        g: color.g,
        b: color.b,
        size_enum: 1
        }
      end
      

      args.outputs[@card_composite_tooltip_ref].primitives << 
      {
      x: 160,
      y: 65,
      text: "Charges",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 1
      }

      args.outputs[@card_composite_tooltip_ref].primitives << 
      {
      x: 160,
      y: 35,
      text: "#{@uses_left} / #{@max_uses}",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 1
      }

    # args.outputs.labels << parsed_.map_with_index do |s, i|
    #   {
    #     x: 80,
    #     y: 80,
    #     anchor_x: 0.5,
    #     anchor_y: i,
    #     text: s
    #   }
    # end

    args.outputs.primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      path: @card_composite_tooltip_ref,
      primitive_marker: :sprite
    }
  end

  def trait_color?(trait)
    case trait
    when $traits[:damage]
      {
        r: 255,
        g: 0,
        b: 0,
      }
    when $traits[:healing]
      {
        r: 0,
        g: 255,
        b: 0,
      }
    end
  end
end
