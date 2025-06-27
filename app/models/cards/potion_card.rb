# frozen_string_literal: true
class PotionCard < Card
  attr :free_floating

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
  end

  def save_data?
    { id: @id.to_s, uses_left: @uses_left.to_s }
  end

  def calc_hover
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
    if @hovered and front_card? and not @grabbed
      @tt_f_a = 255
    else
      @tt_f_a = 0
    end

    @tt_f_a = 0 if @grabbed
  end

  def calc_position(num_cards, index)
    if @free_floating
      @f_pos.y = 110 if @pos.y < 110
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
    else
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
      end
    end

    super
  end
end
