# frozen_string_literal: true
class IngredientRewardCard < Card

  def calc_position(num_cards, index)
    x_s = (GTK.args.grid.w / 2) - (num_cards * ((@w + @padding + 100) / 2))
    @f_pos.x = x_s + (index * (@w + @padding + 100)) - 20 # slight offset to x position if cards are "fanned" because the angling makes them look off-center otherwise

    if @hovered
      @fw = 230
      @fh = 230
    else
      @fw = 190
      @fh = 190
      @f_pos.y =
        @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
      @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 2
    end
    super
  end

  def use()
    puts "ADDED #{@id} TO PLAYER INVENTORY"
    $player.ingredients.add(GameUtils.gen_new_card(@id))
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
