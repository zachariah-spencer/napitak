# frozen_string_literal: true
class RecipeCard < Card
  attr_gtk
  attr :hovered, :pos, :page

  def initialize(x:, y:, w:, h:, id:, page: -1)
    @entity_id = GameUtils.new_id?
    @floating_seed = Numeric.rand(0.0..100.0)

    @id = id

    @pos = { x: x, y: y }
    @w = w
    @h = h
    @angle = 0
    @tt_a = 0

    @f_pos = { x: x, y: y }
    @hovered_f_pos = { x: x, y: y }
    @fw = w
    @fh = h
    @f_angle = 0
    @tt_f_a = 0

    @hovered_w = w * 1.25
    @hovered_h = h * 1.25
    @normal_w = w
    @normal_h = h
    @card_back_img = %w[
      sprites/card_back_1.png
      sprites/card_back_2.png
      sprites/card_back_3.png
    ].sample

    # Setup for potion data
    if GameUtils.is_potion(@id)
      @name = $PIDS[id].name
      @desc = $PIDS[id].desc
      @fc = $PIDS[id].fc
      @max_uses = $PIDS[id].max_uses
      @potencies = $PIDS[id].traits
      @potion_image = $PIDS[id].path
      @ingredient_images = []
      $PIDS[id].ingredients.keys.each do |iid|
        @ingredient_images << $IIDS[iid].path
      end

      # Setup for ingredient data
    else
      @name = $IIDS[id].name
      @desc = nil
      @fc = nil
      @max_uses = nil
      @potencies = nil
      @potion_image = $IIDS[id].path
      @ingredient_images = []
      if not $IIDS[id].base
        $IIDS[id].ingredients.keys.each do |iid|
          @ingredient_images << $IIDS[iid].path
        end
      end
      puts @ingredient_images
    end

    @card_composite_sprite_ref = :"card_composite_#{@entity_id}"
    @card_composite_tooltip_ref = :"card_composite_tooltip_#{@entity_id}"

    @r = 255 # Numeric.rand(100..200)
    @g = 255 # Numeric.rand(50..100)
    @b = 255 # Numeric.rand(100..200)
    @hovered = false
    @page = page
    @anchored = false
    @vx = 0.0
    @vy = 0.0
  end

  def tick()
    calc_hover
    calc_sprite_updates
    calc_render_target(GTK.args)
  end

  def calc_hover
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
    if @hovered
      @fw = @hovered_w
      @fh = @hovered_h
      @tt_f_a = 255 # if is_potion(@id)
    else
      @fw = @normal_w
      @fh = @normal_h
      @tt_f_a = 0
    end
  end

  def rect
    { id: @entity_id, x: @pos.x, y: @pos.y, w: @w, h: @h, angle: @angle }
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
      x: GTK.args.grid.w / 2 - @w * 2 / 2,
      y: GTK.args.grid.h / 2 - @h * 2 / 2,
      w: @w * 2,
      h: @h * 2,
      a: @tt_a,
      angle: 0,
      path: @card_composite_tooltip_ref,
      primitive_marker: :sprite
    }
    return card_sprite, tt_sprite
  end

  def calc_sprite_updates
    if not @hovered
      @f_pos.y =
        @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.03) * 0.05)
      @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.005) * 2
    end

    @w = @w.lerp @fw, 0.2
    @h = @h.lerp @fh, 0.2
    @hovered_f_pos.x = @f_pos.x - (@fw * 0.01)
    @hovered_f_pos.y = @f_pos.y - (@fh * 0.01)
    if @hovered
      @pos.x = @pos.x.lerp @hovered_f_pos.x, 0.2
      @pos.y = @pos.y.lerp @hovered_f_pos.y, 0.2
    else
      @pos.x = @pos.x.lerp @f_pos.x, 0.2
      @pos.y = @pos.y.lerp @f_pos.y, 0.2
    end
    @angle = @angle.lerp @f_angle, 0.2
    @tt_a = @tt_a.lerp(@tt_f_a, 0.2) if @tt_a && @tt_f_a
  end

  def calc_render_target(args)
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
      path: @potion_image
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
    }

    args.outputs.primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      path: @card_composite_sprite_ref,
      primitive_marker: :sprite
    }

    render_tooltip(args) if @hovered
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
      primitive_marker: :solid
    }
    parsed_name = String.wrapped_lines @name, 25
    args.outputs[
      @card_composite_tooltip_ref
    ].primitives << parsed_name.map_with_index do |s, i|
      {
        x: @w,
        y: @h * 2 - 80,
        text: "#{s}",
        anchor_x: 0.5,
        anchor_y: i,
        r: 255,
        g: 255,
        b: 255,
        size_px: 30
      }
    end

    args.outputs[@card_composite_tooltip_ref].primitives << {
      x: @w - 50,
      y: @h * 1.2,
      w: 100,
      h: 100,
      angle: 0,
      path: @potion_image
    }

    if @ingredient_images
      start_x = @w - (25 * @ingredient_images.size)
      @ingredient_images.each_with_index do |img_path, idx|
        args.outputs[@card_composite_tooltip_ref].primitives << {
          x: start_x + ((50 * idx)),
          y: @h / 2,
          w: 40,
          h: 40,
          angle: 0,
          path: img_path
        }
      end
    end

    if GameUtils.is_potion(@id)
      parsed_description = String.wrapped_lines @desc, 30
      # add a label in the center of the render target
      args.outputs[
        @card_composite_tooltip_ref
      ].primitives << parsed_description.map_with_index do |s, i|
        {
          x: @w,
          y: @h,
          text: "#{s}",
          anchor_x: 0.5,
          anchor_y: i,
          r: 255,
          g: 255,
          b: 255,
          size_px: 22
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
        x: @w * 2 - 60,
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

      # @potencies.each_with_index do |trait, i|
      #   trait.each do |trait_id, potency_val|
      #     color = trait_color?(trait_id)
      #
      #     start_x = @w * 2 - 50 - ((@potencies.size * 17.5) / 2)
      #     args.outputs[@card_composite_tooltip_ref].primitives << {
      #       x: start_x + (i * 25),
      #       y: 35,
      #       text: "#{potency_val.to_s}",
      #       anchor_x: 0.5,
      #       anchor_y: 0.5,
      #       r: color.r,
      #       g: color.g,
      #       b: color.b,
      #       size_enum: 1
      #     }
      #   end
      # end

      args.outputs[@card_composite_tooltip_ref].primitives << {
        x: @w,
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
        x: @w,
        y: 35,
        text: "#{@max_uses}",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255,
        size_enum: 1
      }
    end

    args.outputs.primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      path: @card_composite_tooltip_ref,
      primitive_marker: :sprite
    }
  end
end
