# frozen_string_literal: true
class RecipeCard < Card
  attr_gtk
  attr :hovered, :pos, :page, :faded, :viewed

  def initialize(x:, y:, w:, h:, id:, page: -1)
    @anim_seed = Numeric.rand(0..3)
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
    @card_back_img = "sprites/card_sheet.png"

    # Setup for potion data
    if GameUtils.is_potion(@id)
      @name = $PIDS[id].name
      @desc = $PIDS[id].desc
      @fc = $PIDS[id].fc
      @max_uses = $PIDS[id].max_uses
      @potencies = $PIDS[id].traits
      @potion_image = $PIDS[id].path
      # Build ingredient image list including duplicates based on required counts
      @ingredient_images = []
      $PIDS[id].ingredients.each do |iid, amt|
        amt.times { @ingredient_images << $IIDS[iid].path }
      end

      # Setup for ingredient data
    else
      @name = $IIDS[id].name
      @desc = nil
      @fc = nil
      @max_uses = nil
      @potencies = nil
      @potion_image = $IIDS[id].path
      # Build ingredient image list including duplicates for craftable ingredients
      @ingredient_images = []
      if not $IIDS[id].base
        $IIDS[id].ingredients.each do |iid, amt|
          amt.times { @ingredient_images << $IIDS[iid].path }
        end
      end
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
    @flipped = false
    @flipping_tick = nil
    @viewed = false
    @faded = true
  end

  def clicked?
    GTK.args.inputs.mouse.click && Geometry.intersect_rect?(GTK.args.inputs.mouse, rect) && !@faded
  end

  def flip(flipped)
    @flipped = flipped
    @flipping_tick = Kernel.tick_count
    $AUDIO_SERVICE.play_sound(:card_flip)
  end

  def tick()
    flip(!@flipped) if clicked?
    @viewed = !@viewed if clicked?

    calc_hover if !@faded
    calc_sprite_updates
    calc_render_target(GTK.args)
  end

  def calc_hover
    was_hovered = @hovered
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
    if @hovered
      @fw = @hovered_w
      @fh = @hovered_h
    else
      @fw = @normal_w
      @fh = @normal_h
    end

      calc_hover_audio(was_hovered)
  end

  def rect
    { id: @entity_id, x: @pos.x, y: @pos.y, w: @w, h: @h, angle: @angle, anchor_x: 0.5, anchor_y: 0.5 }
  end

  def prefab
    card_sprite = {
      x: @pos.x,
      y: @pos.y,
      w: @w,
      h: @h,
      angle: @angle,
      path: @card_composite_sprite_ref,
      anchor_x: 0.5,
      anchor_y: 0.5,
      a: @faded ? 60 : 255,
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
    if !@viewed
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
    else
      @w = @w.lerp 512, 0.2
      @h = @h.lerp 512, 0.2
      @pos.x = @pos.x.lerp GTK.args.grid.w / 2, 0.2
      @pos.y = @pos.y.lerp GTK.args.grid.h / 2, 0.2
    end

  end

  def calc_render_target_background(args, prefab_alpha = 255)
    card_sprite_frame =
      0.frame_index(
        count: 4,
        hold_for: @hovered ? 10 : 30,
        repeat: true,
        repeat_index: 0,
        tick_count_override: Kernel.tick_count
      )

    card_sprite_frame += @anim_seed
    card_sprite_frame -= 4 if card_sprite_frame > 3

    if @flipping_tick
      flipping_frames = Numeric.frame_index(start_at: @flipping_tick,
                                            count: 4,
                                            hold_for: 3,
                                            repeat: false
                                          )
    end

    if flipping_frames
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: 0,
        y: 0,
        w: @w,
        h: @h,
        angle: 0,
        r: @r,
        g: @g,
        b: @b,
        a: prefab_alpha,
        path: "sprites/card_flipping-sheet-4.png",
        tile_x: (flipping_frames * 128),
        tile_y: 0,
        tile_w: 128,
        tile_h: 128
      }
    else
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: 0,
        y: 0,
        w: @w,
        h: @h,
        angle: 0,
        r: @r,
        g: @g,
        b: @b,
        a: prefab_alpha,
        path: @card_back_img,
        tile_x: (card_sprite_frame * 128),
        tile_y: 0,
        tile_w: 128,
        tile_h: 128
      }
    end
  end

  def calc_render_target(args)
    # define the dimensions of the combined sprite
    # the name of the combined sprite is :card_composite_sprite_ref
    args.outputs[@card_composite_sprite_ref].w = @w
    args.outputs[@card_composite_sprite_ref].h = @h
    prefab_alpha = 255

    calc_render_target_background(args, prefab_alpha)

    if @flipped
      GameUtils.is_potion(self.id) ? calc_rt_card_back_potion(args) : calc_rt_card_back_ingredient(args)
    else
      calc_rt_card_front(args)
    end

    calc_rt_export(args)
  end

  def calc_rt_card_back_potion(args)
    parsed_name = String.wrapped_lines @name, 15
    args.outputs[
      @card_composite_sprite_ref
    ].primitives << parsed_name.map_with_index do |s, i|
      {
        x: @w / 2,
        y: @h - 80,
        text: "#{s}",
        font: $FONT,
        anchor_x: 0.5,
        anchor_y: i,
        r: 255,
        g: 255,
        b: 150,
        size_px: 32
      }
    end

    parsed_description = String.wrapped_lines @desc, 40
    # add a label in the center of the render target
    args.outputs[
      @card_composite_sprite_ref
    ].primitives << parsed_description.map_with_index do |s, i|
      {
        x: @w / 2,
        y: @h / 1.5,
        text: "#{s}",
        font: $FONT,
        anchor_x: 0.5,
        anchor_y: i,
        r: 255,
        g: 255,
        b: 150,
        size_enum: 1
      }
    end

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 5,
      y: @h / 2.5,
      text: "Focus",
      font: $FONT,
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_px: 32
    }

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 2,
      y: @h / 2.5,
      text: "Base",
      font: $FONT,
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_px: 32
    }

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 2 - 28,
      y: @h / 3.25 - 28 + 4,
      w: 56,
      h: 56,
      path: $IIDS[$PIDS[self.id][:primary_base_ingredient_id]][:path]
    }

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 5,
      y: @h / 3.25,
      text: "#{@fc}",
      font: $FONT,
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 0,
      g: 150,
      b: 150,
      size_px: 64
    }

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 1.25,
      y: @h / 2.5,
      text: "Charges",
      font: $FONT,
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_px: 32,
    }

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 1.25,
      y: @h / 3.25,
      text: "#{@max_uses}",
      font: $FONT,
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 200,
      g: 100,
      b: 200,
      size_px: 64
    }

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 2,
      y: @h / 4.75,
      text: "Effects",
      font: $FONT,
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_px: 32
    }

    if @ingredient_images
      start_x = @w / 2 - (32 * @ingredient_images.size)
      @ingredient_images.each_with_index do |img_path, idx|
        args.outputs[@card_composite_sprite_ref].primitives << {
          x: start_x + ((64 * idx)),
          y: @h / 2,
          w: 64,
          h: 64,
          angle: 0,
          path: img_path
        }
      end
    end

gap = 32
n = @potencies.length
center_x = @w / 2
start_x = center_x - ((n - 1) * gap) / 2.0

damage_trait = nil
damage_x = nil
damage_color = nil

@potencies.each_with_index do |trait, i|
  trait.each do |trait_id, potency_val|
    color = trait_color?(trait_id)
    x = start_x + (i * gap)

    if trait_id == $CARD_TRAITS[:damage]
      damage_trait = potency_val
      damage_x = x
      damage_color = $DAMAGE_TYPE_COLORS[damage_trait[:type]]
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: x, y: @h / 8,
        text: potency_val.amount.to_s,
        font: $FONT,
        anchor_x: 0.5, anchor_y: 0.5,
        r: color.r, g: color.g, b: color.b,
        size_px: 64
      }
    else
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: x, y: @h / 8,
        text: potency_val.to_s,
        font: $FONT,
        anchor_x: 0.5, anchor_y: 0.5,
        r: color.r, g: color.g, b: color.b,
        size_px: 64
      }
    end
  end
end

# Draw a colored sprite under the damage label (uses :pixel tinted to damage color).
if damage_trait && damage_x && damage_color
  args.outputs[@card_composite_sprite_ref].primitives << {
    x: damage_x - 11,                # center a 16px sprite under the text
    y: (@h / 7.75) - 32,               # "under" the label (lower on screen)
    w: 22, h: 4,
    path: :pixel,                   # 1px white, tinted via RGB
    r: damage_color.r, g: damage_color.g, b: damage_color.b, a: 255,
    primitive_marker: :sprite
  }
end

    # damage_potency_val_x = 0
    # damage_trait = nil
    # @potencies.each_with_index do |trait, i|
    #   trait.each do |trait_id, potency_val|
    #     color = trait_color?(trait_id)
    #     start_x = @w / 2
# 
    #     if trait_id == $CARD_TRAITS[:damage]
    #       damage_trait = potency_val
    #       damage_potency_val_x = start_x + (i * 25)
    #       args.outputs[@card_composite_sprite_ref].primitives << {
    #         x: damage_potency_val_x,
    #         y: @h / 2,
    #         text: "#{potency_val.amount.to_s}",
    #         font: $FONT,
    #         anchor_x: 0.5,
    #         anchor_y: 0.5,
    #         r: color.r,
    #         g: color.g,
    #         b: color.b,
    #         size_enum: 1
    #       }
    #     else
    #       args.outputs[@card_composite_sprite_ref].primitives << {
    #         x: start_x + (i * 25),
    #         y: @h / 2,
    #         text: "#{potency_val.to_s}",
    #         font: $FONT,
    #         anchor_x: 0.5,
    #         anchor_y: 0.5,
    #         r: color.r,
    #         g: color.g,
    #         b: color.b,
    #         size_enum: 1
    #       }
    #     end
    #   end
    # end
# 
    # if damage_trait
    #   args.outputs[@card_composite_sprite_ref].primitives << {
    #     x: damage_potency_val_x - 5 - 15,
    #     y: 35 - 5,
    #     w: 10,
    #     h: 10,
    #     path: $DAMAGE_TYPE_SPRITES[damage_trait[:type]],
    #     primitive_marker: :sprite
    #   }
    # end
  end

  def calc_rt_card_back_ingredient(args)
    parsed_name = String.wrapped_lines @name, 15
    args.outputs[
      @card_composite_sprite_ref
    ].primitives << parsed_name.map_with_index do |s, i|
      {
        x: @w / 2,
        y: @h - 128,
        text: "#{s}",
        font: $FONT,
        anchor_x: 0.5,
        anchor_y: i,
        r: 255,
        g: 255,
        b: 150,
        size_px: 32
      }
    end

    if !@ingredient_images.empty?
      start_x = @w / 2 - (64 * @ingredient_images.size)
      @ingredient_images.each_with_index do |img_path, idx|
        args.outputs[@card_composite_sprite_ref].primitives << {
          x: start_x + ((128 * idx)),
          y: @h / 2 - 64,
          w: 128,
          h: 128,
          angle: 0,
          path: img_path
        }
      end
    else
      args.outputs[@card_composite_sprite_ref].primitives << {
          x: @w / 2,
          y: @h / 2,
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 255,
          g: 255,
          b: 255,
          size_px: 128,
          text: "BASE",
          font: $FONT,
          primitive_marker: :label
        }
    end
  end

  def calc_rt_card_front(args)
    prefab_alpha = 255

    calc_render_target_background(args, prefab_alpha)

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 4,
      y: @h / 4,
      w: @w / 2,
      h: @h / 2,
      angle: 0,
      a: prefab_alpha,
      path: @potion_image
    }

    args.outputs[@card_composite_sprite_ref].primitives << {
        x: @w / 2,
        y: @h / 1.25,
        text: "#{@name}",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 150,
        size_px: @free_floating ? 16 : 20,
        a: prefab_alpha,
        font: $FONT
      }

    if GameUtils.is_potion(self.id)
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: @w / 2 - 8,
        y: @free_floating ? 12 : 20,
        w: 16,
        h: 16,
        angle: 0,
        a: prefab_alpha,
        path: $IIDS[$PIDS[self.id][:primary_base_ingredient_id]][:path]
      }

      if @focus_mod == 0
        args.outputs[@card_composite_sprite_ref].primitives << {
          x: 24,
          y: @free_floating ? 20 : 28,
          text: "#{@fc}",
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 0,
          g: 150,
          b: 150,
          size_px: @free_floating ? 16 : 26,
          a: prefab_alpha,
          font: $FONT
        }
      else
        args.outputs[@card_composite_sprite_ref].primitives << {
          x: 24,
          y: @free_floating ? 20 : 28,
          text: "#{@fc}",
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 0,
          g: 255,
          b: 130,
          size_px: @free_floating ? 16 : 26,
          a: prefab_alpha,
          font: $FONT
        }
      end

      args.outputs[@card_composite_sprite_ref].primitives << {
        x: @w - 16 - 12,
        y: @free_floating ? 20 : 28,
        text: "#{@max_uses}",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 200,
        g: 100,
        b: 200,
        size_px: 26,
        a: prefab_alpha,
        font: $FONT
      }
    end
  end

  def calc_rt_export(args)
    args.outputs.primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      path: @card_composite_sprite_ref,
      primitive_marker: :sprite
    }
  end

  # def calc_render_target(args)
  #   args.outputs[@card_composite_sprite_ref].w = @w
  #   args.outputs[@card_composite_sprite_ref].h = @h
# 
  #   calc_render_target_background(args)
  #   args.outputs[@card_composite_sprite_ref].primitives << {
  #     x: @w / 2 - 40,
  #     y: @h / 2 - 40,
  #     w: 80,
  #     h: 80,
  #     angle: 0,
  #     path: @potion_image
  #   }
# 
  #   # add a label in the center of the render target
  #   args.outputs[@card_composite_sprite_ref].primitives << {
  #     x: @w / 2,
  #     y: @h / 1.25,
  #     text: "#{@name}",
  #     anchor_x: 0.5,
  #     anchor_y: 0.5,
  #     r: 255,
  #     g: 255,
  #     b: 255,
  #     size_px: 20,
  #   }
# 
  #   args.outputs.primitives << {
  #     x: 0,
  #     y: 0,
  #     w: @w,
  #     h: @h,
  #     path: @card_composite_sprite_ref,
  #     primitive_marker: :sprite
  #   }
# 
  #   render_tooltip(args) if @hovered
  # end

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
