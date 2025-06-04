require_relative "ingredient_card.rb"

class IngredientRewardCard < IngredientCard
  def calc_position(num_cards, index)
    x_s = (GTK.args.grid.w / 2) - (num_cards * ((@w + @padding + 100) / 2))
    if !@grabbed
      @f_pos.x = x_s + (index * (@w + @padding + 100)) - 20 # slight offset to x position if cards are "fanned" because the angling makes them look off-center otherwise
      max_angle = -15.0 # Maximum rotation in degrees for the extreme cards
      max_y = 30
      y_offset = 200
      center_index = (num_cards - 1) / 2.0
      relative_index = index - center_index
      normalized_distance = (index - center_index).abs / center_index

      if num_cards == 2
        @f_angle = (relative_index / center_index) * max_angle
        @f_pos.y = max_y + y_offset
      elsif num_cards == 3
        @f_angle = (relative_index / center_index) * 0.75 * max_angle
        @f_pos.y = max_y * (1 - (1 * (normalized_distance)**2)) + 25 + y_offset
      elsif num_cards == 4
        @f_angle = (relative_index / center_index) * max_angle
        @f_pos.y =
          max_y * (1 - (1.5 * (normalized_distance)**2)) + 50 + y_offset
      elsif num_cards > 1
        # Calculate the card's rotation as a fraction of the maximum angle
        @f_angle = (relative_index / center_index) * max_angle
        @f_pos.y =
          max_y * (1 - (2 * (normalized_distance)**2)) +
            (0.75 * (12.5 * num_cards)) + y_offset # +  ( 2 * (normalized_distance)**3 ) ) )# LINEAR: ((1 - normalized_distance) * max_y)
      else
        @f_angle = 0.0
        @f_pos.y = max_y + y_offset
      end

      @pos.x = @pos.x.lerp @f_pos.x, 0.2
      @pos.y = @pos.y.lerp @f_pos.y, 0.2
      @w = @w.lerp @fw, 0.2
      @h = @h.lerp @fh, 0.2
    else
      @f_angle = 0
    end
    @angle = @angle.lerp @f_angle, 0.2
  end

  def use()
    puts "ADDED #{@id} TO PLAYER INVENTORY"
    $player.ingredients.add(gen_new_card(@id))
    @needs_removed = true
  end
end
