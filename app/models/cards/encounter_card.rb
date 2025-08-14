# frozen_string_literal: true

class EncounterCard < Card
  attr :f_pos, :selected, :fw

  def initialize(id)
    super(id, GameUtils.new_id?, $ENCOUNTERS[id].name, 0, $ENCOUNTERS[id].path)
    @selected = nil
    @a = 255
    @fading = false
    @is_selected = false
  end

  def fade_out
    @fading = true
  end

  def tick
    if !$game.input_locked
      calc_hover
      calc_click
    else
      @hovered = false
    end
    calc_position(-1, -1)
    calc_render_target(GTK.args)

    @a -= 15 if @fading
  end

  def calc_hover
    hovered_last_tick = @hovered
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
    calc_hover_audio(hovered_last_tick)
  end

  def calc_hover_audio(was_hovered)
    if was_hovered != @hovered && @hovered && !@grabbed
      $AUDIO_SERVICE.play_sound(:card_hover)
    end
    if was_hovered != @hovered && !@hovered && !@grabbed
      $AUDIO_SERVICE.play_sound(:card_unhover)
    end
  end

  def calc_click
    if (
         Geometry.intersect_rect?(GTK.args.inputs.mouse, rect) and
           GTK.args.inputs.mouse.click
       )
      puts "#{@entity_id} || #{@name} : was clicked"
      @selected = { id: @id, data: $ENCOUNTERS[@id] }
      $AUDIO_SERVICE.play_sound(:encounter_selected)
      $AUDIO_SERVICE.play_sound(:card_grab)
    end
  end

  def pop_clicked
    encounter = @selected
    @is_selected = true
    @selected = nil
    encounter
  end

  def prefab
      {
        x: @pos.x,
        y: @pos.y,
        w: @w,
        h: @h,
        a: @a,
        angle: @angle,
        path: @card_composite_sprite_ref,
        primitive_marker: :sprite
      }
  end

  def rect
    { id: @entity_id, x: @pos.x, y: @pos.y, w: @w, h: @h, angle: @angle }
  end

  def calc_position(num_cards, index)
    if !@hovered
      @f_pos.y =
        @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
      @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.005) * 2
    end

    if !@fading && !@is_selected
      if @hovered
        @fw = 230
        @fh = 230
      else
        @fw = 190
        @fh = 190
      end
    end

    super
  end

  def calc_render_target(args)
    # start_looping_at = Numeric.rand(0..3)
    card_sprite_frame =
      0.frame_index(
        count: 4,
        hold_for: @hovered ? 8 : 30,
        repeat: true,
        repeat_index: 0,
        tick_count_override: Kernel.tick_count
      )

    card_sprite_frame += @anim_seed
    card_sprite_frame -= 4 if card_sprite_frame > 3

    prefab_alpha = 255
    prefab_alpha = (@uses_left > 0) ? 255 : 150 if GameUtils.is_potion(self.id)
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
      r: 50,
      g: 255,
      b: 255,
      a: prefab_alpha,
      path: @card_back_img,
      tile_x: (card_sprite_frame * 128),
      tile_y: 0,
      tile_w: 128,
      tile_h: 128
    }

    
    if @name == "Wolf"
      sprite_frame = 0.frame_index(
                      count: 3,
                      hold_for: 30,
                      repeat: true,
                      repeat_index: 0,
                      tick_count_override: Kernel.tick_count)
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: @w / 4,
        y: @h / 4,
        w: @w / 2,
        h: @h / 2,
        angle: 0,
        a: prefab_alpha,
        path: @img,
        tile_x: (sprite_frame * 128),
        tile_y: 0,
        tile_w: 128,
        tile_h: 128,
      }
    else
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: @w / 3,
        y: @h / 3,
        w: @w / 3,
        h: @h / 3,
        angle: 0,
        a: prefab_alpha,
        path: @img,
      }
    end

    parsed_name = String.wrapped_lines @name, 15
    args.outputs[
      @card_composite_sprite_ref
    ].primitives << parsed_name.map_with_index do |s, i|
      {
        x: @w / 2,
        y: @h - 40,
        text: "#{s}",
        anchor_x: 0.5,
        anchor_y: i,
        r: 255,
        g: 255,
        b: 255,
        font: $FONT,
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
