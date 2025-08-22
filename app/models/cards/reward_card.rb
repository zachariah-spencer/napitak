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
      x_s = (GTK.args.grid.w / 2) - (num_cards * ((@w + @padding + 100) / 2))
      @f_pos.x = x_s + (index * (@w + @padding + 100)) + 32 # slight offset to x position if cards are "fanned" because the angling makes them look off-center otherwise

      if @hovered
        @fw = 180
        @fh = 180
      else
        @fw = 150
        @fh = 150
        @f_pos.y =
          @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
        @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 2
      end
    end
    super
  end

  def instant_calc_position(num_cards, index, y)
    x_s = (GTK.args.grid.w / 2) - (num_cards * ((@w + @padding + 100) / 2))
    x_pos = x_s + (index * (@w + @padding + 100)) + 32 # slight offset to x position if cards are "fanned" because the angling makes them look off-center otherwise
    instant_set_position(x: x_pos, y: y)
  end

  def use()
    GameUtils.sparkle_particle(x: @pos.x, y: @pos.y, r: 255, g: 255, b: 0)
    if @id == "s001"
      #inc focus
      $player.maximum_focus += 1
    elsif @id == "s002"
      #inc hp
      $player.maximum_hp += 5
    else
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
      primitive_marker: :sprite
    }
    return card_sprite
  end
end
