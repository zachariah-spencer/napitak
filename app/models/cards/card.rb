# frozen_string_literal: true

class Card
  attr_accessor :grabbed,
                :needs_removed,
                :pos,
                :f_pos,
                :entity_id,
                :w,
                :h,
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

  def initialize(
    id,
    entity_id,
    name,
    fc,
    img,
    max_uses = 0,
    desc = "",
    potencies = {},
    uses_left: nil
  )
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

    @card_back_img = %w[
      sprites/card_back_1.png
      sprites/card_back_2.png
      sprites/card_back_3.png
    ].sample
    @img = img
    @max_uses = max_uses
    @uses_left = uses_left || max_uses
    @card_composite_sprite_ref = :"card_composite_#{entity_id}"
    @card_composite_tooltip_ref = :"card_composite_tooltip_#{entity_id}"

    @r = 255 # Numeric.rand(100..200)
    @g = 255 # Numeric.rand(50..100)
    @b = 255 # Numeric.rand(100..200)

    @grabbed = false
    @selected = false
    @hovered = false
    @tt_a = 0
    @tt_f_a = 0
    @needs_removed = false
    @activation_time = 0.0
    calc_render_target GTK.args
  end

  def instant_set_position(x: GTK.args.grid.w / 2, y: GTK.args.grid.h / 2)
    @pos = { x: x, y: y }
    @f_pos = { x: x, y: y }
  end

  def tick()
    calc_hover
    calc_render_target(GTK.args)
  end

  def save_data?
    @id
  end

  def calc_position(num_cards, index)
    interpolate_attributes
  end

  def rect
    { id: @entity_id, x: @pos.x, y: @pos.y, w: @w, h: @h, angle: @angle }
  end

  def calc_hover
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)

    if @hovered and not @grabbed
      @tt_f_a = 255
    else
      @tt_f_a = 0
    end

    @tt_f_a = 0 if @grabbed
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
    return card_sprite, tt_sprite
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
      x: @w / 2 - 40,
      y: @h / 2 - 40,
      w: 80,
      h: 80,
      angle: 0,
      path: @img
    }

    # add a label in the center of the render target
    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 2,
      y: @h / 1.25,
      text: "#{@name}",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_px: 20,
      font: "fonts/eaglelake.ttf"
    }

    args.outputs.primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      path: @card_composite_sprite_ref,
      primitive_marker: :sprite
    }

    render_tooltip(args) if GameUtils.is_potion(self.id) && @hovered
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
      b: 20,
      a: 220,
      primitive_marker: :solid
    }
    parsed_name = String.wrapped_lines @name, 15
    args.outputs[
      @card_composite_tooltip_ref
    ].primitives << parsed_name.map_with_index do |s, i|
      {
        x: 165,
        y: 275,
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
    args.outputs[
      @card_composite_tooltip_ref
    ].primitives << parsed_description.map_with_index do |s, i|
      {
        x: 165,
        y: 200,
        text: "#{s}",
        anchor_x: 0.5,
        anchor_y: i,
        r: 255,
        g: 255,
        b: 255,
        size_enum: 1
      }
    end

    args.outputs[@card_composite_tooltip_ref].primitives << {
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

    args.outputs[@card_composite_tooltip_ref].primitives << {
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

    args.outputs[@card_composite_tooltip_ref].primitives << {
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

    damage_potency_val_x = 0
    damage_trait = nil
    @potencies.each_with_index do |trait, i|
      trait.each do |trait_id, potency_val|
        color = trait_color?(trait_id)
        start_x = @w * 2 - 50 - ((@potencies.size * 17.5) / 2)

        if trait_id == $CARD_TRAITS[:damage]
          damage_trait = potency_val
          damage_potency_val_x = start_x + (i * 25)
          args.outputs[@card_composite_tooltip_ref].primitives << {
            x: damage_potency_val_x,
            y: 35,
            text: "#{potency_val.amount.to_s}",
            anchor_x: 0.5,
            anchor_y: 0.5,
            r: color.r,
            g: color.g,
            b: color.b,
            size_enum: 1
          }
        else
          args.outputs[@card_composite_tooltip_ref].primitives << {
            x: start_x + (i * 25),
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
      end
    end

    if damage_trait
      args.outputs[@card_composite_tooltip_ref].primitives << {
        x: damage_potency_val_x - 5 - 15,
        y: 35 - 5,
        w: 10,
        h: 10,
        path: $DAMAGE_TYPE_SPRITES[damage_trait[:type]],
        primitive_marker: :sprite
      }
    end

    args.outputs[@card_composite_tooltip_ref].primitives << {
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

    args.outputs[@card_composite_tooltip_ref].primitives << {
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

    args.outputs.primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      path: @card_composite_tooltip_ref,
      primitive_marker: :sprite
    }
  end

  def interpolate_attributes
    return if @grabbed

    @pos.x = @pos.x.lerp @f_pos.x, 0.2
    @pos.y = @pos.y.lerp @f_pos.y, 0.2
    @w = @w.lerp @fw, 0.2
    @h = @h.lerp @fh, 0.2
    @angle = @angle.lerp @f_angle, 0.2
    @tt_a = @tt_a.lerp(@tt_f_a, 0.2) if @tt_a && @tt_f_a

    @f_pos.y = 0 if @pos.y < 0
    @f_pos.y = GTK.args.grid.h - @h if @pos.y > GTK.args.grid.h - @h

    @f_pos.x = 0 if @pos.x < 0
    @f_pos.x = GTK.args.grid.w - @w if @pos.x > GTK.args.grid.w - @w
  end

  def trait_color?(trait)
    case trait
    when $CARD_TRAITS[:damage]
      { r: 255, g: 0, b: 0 }
    when $CARD_TRAITS[:restoration]
      { r: 0, g: 255, b: 0 }
    when $CARD_TRAITS[:blight]
      { r: 120, g: 150, b: 60 }
    when $CARD_TRAITS[:scorch]
      { r: 255, g: 100, b: 0 }
    when $CARD_TRAITS[:frost]
      { r: 0, g: 255, b: 255 }
    when $CARD_TRAITS[:ward]
      { r: 255, g: 255, b: 0 }
    when $CARD_TRAITS[:mend]
      { r: 0, g: 150, b: 0 }
    end
  end

  def front_card?
    $player.hovered_cards[$player.hovered_cards.size - 1].id == self.entity_id
  end
end
