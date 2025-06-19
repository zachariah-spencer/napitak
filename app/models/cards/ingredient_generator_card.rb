class IngredientGeneratorCard < Card
  def initialize(id)
    super(id, GameUtils.new_id?, $iids[id].name, 0, $iids[id].path)
    @selected = nil
  end

  def tick
    calc_hover
    calc_click
    calc_position(-1, -1)
  end

  def calc_hover
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
  end

  def calc_click
    if (
         Geometry.intersect_rect?(GTK.args.inputs.mouse, rect) and
           GTK.args.inputs.mouse.click
       )
      puts "#{@entity_id} || #{@name} : was clicked"
      @selected = { id: @id, data: $encounters[@id] }
    end
  end

  def pop_clicked
    encounter = @selected
    @selected = nil
    encounter
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
