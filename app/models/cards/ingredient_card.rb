# frozen_string_literal: true

class IngredientCard < Card
  def calc_position(num_cards, index)
    if !@grabbed
      if @selected
        @fw = 200
        @fh = 200
      else
        @fw = 160
        @fh = 160
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

    super
  end
end
