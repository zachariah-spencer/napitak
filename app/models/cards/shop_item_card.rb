class ShopItemCard < Card
  attr_gtk
  attr :f_pos, :selected, :fw, :bought_tick

  def initialize(id)
    super(id, GameUtils.new_id?, $SHOP_ITEMS[id][:name], -1, $SHOP_ITEMS[id][:path])
  @selected = nil
  @anchored = true
  @price = Numeric.rand(1..4)
  @rot_speed = Numeric.rand(0.01..0.04)
  @bought_tick = nil
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

  def buy
    return if $player.feathers < @price && !@bought_tick
    puts "BOUGHT #{@name}"

    $player.feathers -= @price
    @bought_tick = Kernel.tick_count

    if @id == "s001"
      #inc focus
      $player.maximum_focus += 1
    elsif @id == "s002"
      #inc hp
      $player.maximum_hp += 1
    else
      $player.ingredients.add(
        IngredientCard.new(
            @id,
            GameUtils.new_id?,
            $IIDS[@id].name,
            -1,
            $IIDS[@id].path
          )
      )
    end

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
    if @bought_tick
      @fw = @fw.lerp(0, 1.5)
      @fh = @fh.lerp(0, 1.5)
      super
      return
    end

    if @hovered
      @fw = 150
      @fh = 150
    else
      @fw = 128
      @fh = 128
      @f_pos.y =
        @f_pos.y + (Math.sin(@floating_seed + Kernel.tick_count * 0.05) * 0.1)
      @f_angle = Math.sin(@floating_seed + Kernel.tick_count * @rot_speed) * 2
    end

    super
  end

  def calc_render_target(args)
    args.outputs[@card_composite_sprite_ref].labels << {
      x: @w / 2,
      y: @h / 6,
      text: "#{@price}",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_px: 22,
      a: 255,
      font: "fonts/eaglelake.ttf"
    }
    super
  end
end