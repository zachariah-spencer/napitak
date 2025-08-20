# frozen_string_literal: true
class PotionCard < Card
  attr :free_floating, :grabbed_tick, :grabbed_pos, :flipped

  def initialize(
    id,
    entity_id,
    name,
    fc,
    img,
    max_uses = 0,
    desc = "",
    potencies = {},
    uses_left: nil,
    free_floating: false
  )
    super(
      id,
      entity_id,
      name,
      fc,
      img,
      max_uses,
      desc,
      potencies,
      uses_left: uses_left
    )
    @free_floating = free_floating
    @desc = $PIDS[id].desc
    @potencies = $PIDS[id].traits
    @flipped = false
    puts "HERE"
    @grabbed_tick = nil
    @grabbed_pos = { x: 0, y: 0}
  end

  def tick
    super
  end

  def grab
    @grabbed = true
    @grabbed_tick = Kernel.tick_count
    @grabbed_pos = { x: pos.x, y: pos.y }
  end

  def flip(flipped)
    @flipped = flipped
  end

  def release
    @grabbed = false
    @grabbed_tick = nil
    @grabbed_pos = { x: 0, y: 0 }
    flip(false)
  end

  def save_data?
    { id: @id.to_s, uses_left: @uses_left.to_s }
  end

  def calc_hover
    was_hovered = @hovered
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
    if @hovered and front_card? and not @grabbed
      @tt_f_a = 255
    else
      @tt_f_a = 0
    end

    calc_hover_audio(was_hovered) if @activation_time.elapsed_time >= 0.2.seconds

    @tt_f_a = 0 if @grabbed
    @tt_f_a = 255 if $TUTORIAL_HOVERED_CARD&.entity_id == self.entity_id && [3, 4, 5, 6, 7, 8].include?($announcement_manager.current_announcement_id?)
  end

  def calc_hover_audio(was_hovered)
    $AUDIO_SERVICE.play_sound(:card_hover) if was_hovered != @hovered && @hovered && !@grabbed
    $AUDIO_SERVICE.play_sound(:card_unhover) if was_hovered != @hovered && !@hovered && !@grabbed
  end

  def calc_render_target(args)
    puts Kernel.tick_count
    puts "flipped: #{@flipped}"
    # define the dimensions of the combined sprite
    # the name of the combined sprite is :card_composite_sprite_ref
    args.outputs[@card_composite_sprite_ref].w = @w
    args.outputs[@card_composite_sprite_ref].h = @h
    prefab_alpha = 255
    prefab_alpha = (@uses_left > 0) ? 255 : 150 if GameUtils.is_potion(self.id)

    calc_render_target_background(args, prefab_alpha)

    if @flipped
      calc_rt_card_back(args)
    else
      calc_rt_card_front(args)
    end

    calc_rt_export(args)
  end

  def calc_rt_card_back(args)
    
  end

  def calc_rt_card_front(args)
    prefab_alpha = 255
    prefab_alpha = (@uses_left > 0) ? 255 : 150 if GameUtils.is_potion(self.id)

    calc_render_target_background(args, prefab_alpha)

    args.outputs[@card_composite_sprite_ref].primitives << {
      x: @w / 4,
      y: @h / 4,
      w: @w / 2,
      h: @h / 2,
      angle: 0,
      a: prefab_alpha,
      path: @img
    }

    args.outputs[@card_composite_sprite_ref].primitives << {
        x: @w / 2,
        y: @h / 1.25,
        text: "#{@name}",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255,
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
          text: "#{@fc + @focus_mod}",
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
        text: "#{@uses_left}/#{@max_uses}",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 200,
        g: 100,
        b: 200,
        size_px: @free_floating ? 16 : 18,
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

  def calc_position(num_cards, index)
    if @free_floating
      @f_pos.y = 110 if @pos.y < 110
      if !@grabbed
        if @selected
          @fw = 200
          @fh = 200
        else
          @fw = 120
          @fh = 120
          @f_pos.x =
            @f_pos.x +
              (Math.cos(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
          @f_pos.y =
            @f_pos.y +
              (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
          @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.005) * 2
        end
      else
        @f_angle = 0
      end
    else
      if @flipped
        @fw = 256
        @fh = 256
        @f_pos.x = GTK.args.grid.w / 2 - 128
        @f_pos.y = GTK.args.grid.h / 2 - 128
      else
        @fw = 128 + 32
        @fh = 128 + 32
        x_s = (GTK.args.grid.w / 2) - (num_cards * ((@w + @padding) / 2))
        if !@grabbed
          @f_pos.x = x_s + (index * (@w + @padding)) - 40 # slight offset to x position if cards are "fanned" because the angling makes them look off-center otherwise
          max_angle = -15.0 # Maximum rotation in degrees for the extreme cards
          max_y = 30
          center_index = (num_cards - 1) / 2.0
          relative_index = index - center_index
          normalized_distance = (index - center_index).abs / center_index
          if num_cards == 2
            @f_angle = (relative_index / center_index) * max_angle
            @f_pos.y = max_y
          elsif num_cards == 3
            @f_angle = (relative_index / center_index) * 0.75 * max_angle
            @f_pos.y = max_y * (1 - (1 * (normalized_distance)**2)) + 25
          elsif num_cards == 4
            @f_angle = (relative_index / center_index) * max_angle
            @f_pos.y = max_y * (1 - (1.5 * (normalized_distance)**2)) + 50
          elsif num_cards > 1
            # Calculate the card's rotation as a fraction of the maximum angle
            @f_angle = (relative_index / center_index) * max_angle
            @f_pos.y =
              max_y * (1 - (2 * (normalized_distance)**2)) +
                (0.75 * (12.5 * num_cards)) # +  ( 2 * (normalized_distance)**3 ) ) )# LINEAR: ((1 - normalized_distance) * max_y)
          else
            @f_angle = 0.0
            @f_pos.y = max_y
          end
        else
          @f_angle = 0
          @angle = @angle.lerp(@f_angle, 0.2)
        end
      end
    end

    super
  end
end
