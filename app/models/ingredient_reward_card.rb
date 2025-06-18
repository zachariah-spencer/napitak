# frozen_string_literal: true
require_relative "card.rb"

class IngredientRewardCard < Card
  def calc_position(num_cards, index)
    x_s = (GTK.args.grid.w / 2) - (num_cards * ((@w + @padding + 100) / 2))
    @f_pos.x = x_s + (index * (@w + @padding + 100)) - 20 # slight offset to x position if cards are "fanned" because the angling makes them look off-center otherwise
    @f_pos.y = GTK.args.grid.h / 2 - 80

    if @hovered
      @fw = 250
      @fh = 250
    else
      @fw = 225
      @fh = 225
      @f_pos.y =
        @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
      @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 2
    end

    @pos.x = @pos.x.lerp @f_pos.x, 0.2
    @pos.y = @pos.y.lerp @f_pos.y, 0.2
    @w = @w.lerp @fw, 0.2
    @h = @h.lerp @fh, 0.2
    @angle = @angle.lerp @f_angle, 0.2
  end

  def use()
    puts "ADDED #{@id} TO PLAYER INVENTORY"
    $player.ingredients.add(GameUtils.gen_new_card(@id))
    @needs_removed = true
  end
end
