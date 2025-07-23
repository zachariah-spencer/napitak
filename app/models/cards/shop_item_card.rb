class ShopItemCard < Card
  attr :f_pos, :selected, :fw

  def initialize(id)
    super(id, GameUtils.new_id?, $SHOP_ITEMS[id][:name], -1, $SHOP_ITEMS[id][:path])
  @selected = nil
  @anchored = true
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
    @hovered = Geometry.intersect_rect?(GTK.args.inputs.mouse, rect)
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

  def prefab
    {
      x: @pos.x,
      y: @pos.y,
      w: @w,
      h: @h,
      angle: @angle,
      path: @card_composite_sprite_ref,
      primitive_marker: :sprite
    }
  end

  def rect
    { id: @entity_id, x: @pos.x, y: @pos.y, w: @w, h: @h, angle: @angle }
  end

  def calc_position(num_cards, index)
    if @hovered
      @fw = 150
      @fh = 150
    else
      @fw = 128
      @fh = 128
      @f_pos.y =
        @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.08) * 0.2)
      @f_angle = Math.sin(@floating_seed + Kernel.tick_count * 0.005) * 2
    end

    super
  end
end