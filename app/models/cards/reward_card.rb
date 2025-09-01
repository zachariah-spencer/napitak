# frozen_string_literal: true
class RewardCard < Card
  def initialize(id)
    super(
      id,
      GameUtils.new_id?,
      $REWARD_ITEMS[id][:name],
      -1,
      $REWARD_ITEMS[id][:path]
    )
  end

  def calc_position(num_cards, index)
    if !@marked_for_removal
      # Choose target size first so spacing uses the intended width
      target_w = @hovered ? 180 : 150
      target_h = @hovered ? 180 : 150
      @fw = target_w
      @fh = target_h

      # Center cards by their centers across the screen width
      spacing = target_w + @padding + 100
      x_s = (GTK.args.grid.w / 2) - ((num_cards - 1) * (spacing / 2.0))
      @f_pos.x = x_s + (index * spacing)

      # Subtle float animation when not hovered
      unless @hovered
        @f_pos.y = @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
        @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 2
      end
    end
    super
  end

  def instant_calc_position(num_cards, index, y)
    # Use default target width (non-hovered) for initial placement
    target_w = 150
    spacing = target_w + @padding + 100
    x_s = (GTK.args.grid.w / 2) - ((num_cards - 1) * (spacing / 2.0))
    x_pos = x_s + (index * spacing)
    instant_set_position(x: x_pos, y: y)
  end

  def calc_render_target_background(args, prefab_alpha = 255)
    if @id[0] == "s"
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

      args.outputs[@card_composite_sprite_ref].primitives << {
        x: 0,
        y: 0,
        w: @w,
        h: @h,
        angle: 0,
        r: 100,
        g: 0,
        b: 255,
        a: prefab_alpha,
        path: @card_back_img,
        tile_x: (card_sprite_frame * 128),
        tile_y: 0,
        tile_w: 128,
        tile_h: 128
      }
    else
      super
    end
  end

  def use()
    GameUtils.sparkle_particle(
      x: @pos.x,
      y: @pos.y,
      r: 0,
      g: 255,
      b: 255
    )
    $AUDIO_SERVICE.play_sound(:loot_grabbed)

    if @id == "s001"
      #inc focus
      $AUDIO_SERVICE.play_sound(:upgrade_selected)
      $player.inc_focus_shards
    elsif @id == "s002"
      #inc hp
      $AUDIO_SERVICE.play_sound(:upgrade_selected)
      $player.inc_hp_shards
    else
      $AUDIO_SERVICE.play_sound(:bag_insert)
      $player.ingredients.add(
        IngredientCard.new(
          @id,
          GameUtils.new_id?,
          $IIDS[@id].name,
          -1,
          $IIDS[@id].path
        )
      )
    end
    @needs_removed = true
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
      primitive_marker: :sprite
    }
    return card_sprite
  end
end
