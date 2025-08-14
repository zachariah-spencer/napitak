# frozen_string_literal: true

class IngredientCard < Card
  def initialize(
    id,
    new_ent_id = GameUtils.new_id?,
    name = $IIDS[id][:name],
    fc = -1,
    path = $IIDS[id][:path]
  )
    super
    @w = 120
    @h = 120
  end

  def calc_position(num_cards, index)
    if !@marked_for_removal
      @f_pos.y = 110 if @pos.y < 110 && $game.scene == "alchemy_lab"

      if @selected
        @fw = 150
        @fh = 150
      else
        @fw = 120
        @fh = 120
      end

      if !@grabbed
        if @selected
          @fw = 150
          @fh = 150
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
    end

    super
  end
end
