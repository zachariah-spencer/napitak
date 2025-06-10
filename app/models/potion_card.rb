require_relative "card.rb"

class PotionCard < Card

  def initialize(id, entity_id, name, fc, img, max_uses = 0, desc = "", potencies = {})
    super.initialize

    @desc = $pids[id].desc
    @potencies = $pids[id].traits[0]
    puts @potencies
  end

  def calc_hover
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
    if @hovered and front_card?
      @tt_f_a = 255
    else
      @tt_f_a = 0
    end
  end

  def calc_position(num_cards, index)
    x_s = (GTK.args.grid.w / 2) - (num_cards * ((@w + @padding) / 2))
    if !@grabbed
      @f_pos.x = x_s + (index * (@w + @padding)) - 20 # slight offset to x position if cards are "fanned" because the angling makes them look off-center otherwise
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

      @pos.x = @pos.x.lerp @f_pos.x, 0.2
      @pos.y = @pos.y.lerp @f_pos.y, 0.2
      @w = @w.lerp @fw, 0.2
      @h = @h.lerp @fh, 0.2
      @tt_a = @tt_a.lerp(@tt_f_a, 0.2)
    else
      @f_angle = 0
    end
    @angle = @angle.lerp @f_angle, 0.2
  end
end
