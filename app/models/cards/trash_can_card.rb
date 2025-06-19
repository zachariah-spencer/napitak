class TrashCanCard < Card
  def initialize()
    super("-1", GameUtils.new_id?, "Trash", 0, "sprites/square/white.png")
  end

  def tick
    calc_hover
    calc_position(-1, -1)
  end

  def calc_hover
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
  end

  def calc_position(num_cards, index)
      if @hovered
        @fw = 100
        @fh = 100
      else
        @fw = 80
        @fh = 80
        @f_pos.x =
          @f_pos.x +
            (Math.cos(@floating_seed + Kernel.tick_count * 0.01) * 0.01)
        @f_pos.y =
          @f_pos.y +
            (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.01)
        @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 2
      end
    super
  end
end