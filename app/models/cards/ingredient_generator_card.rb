class IngredientGeneratorCard < Card
  def initialize(id)
    super(
      id,
      GameUtils.new_id?,
      $IIDS[id].name,
      0,
      $IIDS[id].path,
      anchored: true
    )
    @selected = nil
  end

  def tick
    if !$game.input_locked
      calc_hover
      calc_click
    else
      @hovered = false
    end
    calc_position(-1, -1)
    calc_render_target(GTK.args)
  end

  def calc_hover
    hovered_last_tick = @hovered
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
    $AUDIO_SERVICE.play_sound(:hover_ingredient_generator, rand_pitch: true) if @hovered != hovered_last_tick && @hovered
    $AUDIO_SERVICE.play_sound(:unhover_ingredient_generator) if @hovered != hovered_last_tick && !@hovered
  end

  def calc_click
    if (
         Geometry.intersect_rect?(GTK.args.inputs.mouse, rect) and
           GTK.args.inputs.mouse.click
       )
      puts "#{@entity_id} || #{@name} : was clicked"
      @selected = { id: @id, data: $ENCOUNTERS[@id] }
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
        @f_pos.x + (Math.cos(@floating_seed + Kernel.tick_count * 0.01) * 0.01)
      @f_pos.y =
        @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.01)
      @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 2
    end
    super
  end
end
