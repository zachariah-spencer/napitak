# frozen_string_literal: true

class AlchemyTable < Scene
  attr :sc_id

  def initialize(max_uses:)
    @sc_id = "alchemy_table"
    @player = $player
    @recipe_book = $recipe_book
    @uses_left = max_uses
    @visible_ingredients = {}
    @visible_potions = {}
    @selected_ingredients = {}
    @ingredients_on_screen = Inventory.new()
    @craftable_potion = nil
    @leave_btn_text = "LEAVE"
    @leave_btn_clicks = 0
    @leave_btn_clicked_tick = nil
    @leave_btn_message_a = 0
    @card_tapped_tick = nil
    @card_tapped = nil
    @brew_anim_tick = nil
    @brew_completed = false

    @ing_menu_widget =
      ScrollListWidget.new(
        items: @player.ingredients.all_cards,
        x: 16,
        y: GTK.args.grid.h / 2 - 245,
        w: 96,
        h: 500
      )
    @pot_menu_widget =
      ScrollListWidget.new(
        items: @player.potions.all_cards,
        x: GTK.args.grid.w - 16 - 96,
        y: GTK.args.grid.h / 2 - 245,
        w: 96,
        h: 500
      )

    @leave_btn =
      Button.new(
        x: GTK.args.grid.w - 64,
        y: 52,
        w: 64 + 8,
        h: 32,
        text: "#{@leave_btn_text}",
        background_color: {
          r: 255,
          g: 0,
          b: 0
        }
      )
    @brew_btn =
      Button.new(
        x: GTK.args.grid.w / 2,
        y: 128 + 32,
        w: 96,
        h: 48,
        text: "Brew",
        background_color: {
          r: 0,
          g: 255,
          b: 100
        }
      )
    @selection_squares = []

    $AUDIO_SERVICE.play_song(:alchemy_encounter)
    update_inventories
  end

  def play_brew_anim
    @brew_anim_tick = Kernel.tick_count
    $AUDIO_SERVICE.play_sound(:brew_action)
    $game.input_locked = true
    @brew_completed = false
  end

  def tick_brew_anim
    if @brew_anim_tick
      puts "BREWANIMTICK ELAPSED TIME: #{@brew_anim_tick.elapsed_time}"
      if @brew_anim_tick.elapsed_time >= 1.0.seconds
        @brew_anim_tick = nil
        $game.input_locked = false
      else
      end
    end
  end

  def render_brew_anim
    if @brew_anim_tick && @brew_anim_tick.elapsed_time < 1.0.seconds
      frames = @brew_anim_tick.frame_index(16, (1.0.seconds / 16), false)
      on_brew_anim_completed if frames == 13 && !@brew_completed

      puts "FRAMES: #{frames}"

      puts "sprites/brew-anim/brew_anim#{frames + 1}.png"
      {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        path: "sprites/brew-anim/brewanim#{frames + 1}.png"
      }
    end
  end

  def on_brew_anim_completed
    craft(@craftable_potion.id)
    @craftable_potion = nil
    @brew_completed = true
  end

  def cleanup
    puts "cleanup alchemy_table.rb"
    super
    state.currently_dragging_card_id = nil
    state.mouse_point_inside_square = nil

    potions_save_data = []
    @player.potions.all_cards.each { |c| potions_save_data << c.save_data? }

    ingredients_save_data = []
    @player.ingredients.all_cards.each do |c|
      ingredients_save_data << c.save_data?
    end

    $files.save_data["player"]["potions"] = potions_save_data
    $files.save_data["player"]["ingredients"] = ingredients_save_data
  end

  def craft(recipe_id)
    if @recipe_book.can_craft?(
      recipe_id,
      ingredients_inventory: @ingredients_on_screen.all_cards
      )
      $AUDIO_SERVICE.play_sound(:brew_action_completed)
      potion = 
        @recipe_book.craft(
          recipe_id,
          ingredients_inventory: @ingredients_on_screen.all_cards
          )
      @selected_ingredients.each do |id, c|
        remove_selection_square(followed_card: c)
      end
      @selected_ingredients.clear

      potion.instant_set_position(
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2
      )
      if !GameUtils.is_potion(potion.id)
        @visible_ingredients[potion.entity_id] = potion
        @ingredients_on_screen.add(potion)
      else
        potion.free_floating = true
        @visible_potions[potion.entity_id] = potion
      end

      puts "CRAFTED #{potion.name}"

      update_uses_left
    else
      puts "CANNOT CRAFT #{recipe_id}"
    end
  end

  def calc_card_return(card)
    if @card_tapped_tick && @card_tapped_tick.elapsed_time < 0.25.seconds && @card_tapped == card
      puts "return card"
      remove_selection_square(followed_card: card)
      state.currently_dragging_card_id = nil
      state.mouse_point_inside_square = nil
      @visible_potions.reject! { |id,c| c == card }
      @selected_ingredients.reject! { |id,c| c == card }
      @visible_ingredients.reject! { |id,c| c == card }
      if GameUtils.is_potion(card.id)
        @pot_menu_widget.add_item(card)
      else
        @ing_menu_widget.add_item(card)
      end
    end
    if card != @card_tapped
      @card_tapped = card
    end

    @card_tapped_tick = Kernel.tick_count
  end

  def refresh(potion_card)
    $AUDIO_SERVICE.play_sound(:potion_recharged)
    potion_card.uses_left = potion_card.max_uses
    potion_card.update_sprite
    update_uses_left
  end

  def update_uses_left
    @uses_left -= 1
    return unless @uses_left <= 0

    puts "USES EXHAUSTED, EXITING ALCHEMY LAB ENCOUNTER"
    leave
  end

  def calc_selected_positions
    spacing = 24
    card_w = 150
    count = @selected_ingredients.keys.length
    return if count <= 0

    total_width = (count * card_w) + ((count - 1) * spacing)
    start_x = GTK.args.grid.w / 2 - (total_width / 2.0) + (card_w / 2.0)

    @selected_ingredients.each_with_index do |(id, card), i|
      card.f_pos.y = 400
      card.f_pos.x = start_x + (i * (card_w + spacing))
    end
  end

  def center_elements(elements, center_x, element_width)
    half_total_width = (elements.length * element_width) / 2.0
    start_x = center_x - half_total_width

    elements.each_with_index.map do |el, i|
      { element: el, x: start_x + (i * element_width + spacing) }
    end
  end

  def leave
    # gather all ingredient cards to return to the player's inventory
    new_ings = []

    if @ing_menu_widget.respond_to?(:items?)
      new_ings.concat(@ing_menu_widget.items?)
    else
      new_ings.concat(@ing_menu_widget.instance_variable_get(:@items))
    end

    # split cards currently on the table into ingredients and potions
    table_cards = @visible_ingredients.values
    selected_cards = @selected_ingredients.values
    new_ings.concat(table_cards.reject { |c| GameUtils.is_potion(c.id) })
    new_ings.concat(selected_cards.reject { |c| GameUtils.is_potion(c.id) })

    # gather potions from the potion menu and any visible/selected potion stacks
    new_pots = []

    if @pot_menu_widget.respond_to?(:items?)
      new_pots.concat(@pot_menu_widget.items?)
    else
      new_pots.concat(@pot_menu_widget.instance_variable_get(:@items))
    end

    new_pots.concat(@visible_potions.values)
    new_pots.concat(table_cards.select { |c| GameUtils.is_potion(c.id) })
    new_pots.concat(selected_cards.select { |c| GameUtils.is_potion(c.id) })
    
    new_pots.each do |c|
      c.free_floating = false
      c.marked_for_removal = false
      c.needs_removed = false
      c.fw = 160
      c.fh = 160
    end

    @player.ingredients = Inventory.new(new_ings)
    @player.potions = Inventory.new(new_pots)

    $game.change_scene(prev_sc: @sc_id, next_scene: "map")
  end

  def tick
    tick_brew_anim
    @ing_menu_widget.tick(GTK.args.inputs)
    @pot_menu_widget.tick(GTK.args.inputs)
    @visible_ingredients.each { |id, c| c.tick }
    @visible_potions.each { |id, c| c.tick }
    @selected_ingredients.each { |id, c| c.tick }
    calc
    @leave_btn.tick
    @brew_btn.tick
  end

  def calc
    if !$game.input_locked
      calc_keyboard_inputs
      calc_mouse_inputs
    else
      calc_inputs_locked
    end
    calc_card_positions
    calc_selected_positions
  end

  def calc_inputs_locked
    all_moveable_cards =
      @visible_ingredients.merge(@selected_ingredients).merge(@visible_potions)

    all_moveable_cards.each { |id, c| c.grabbed = false }

    state.currently_dragging_card_id = nil
    state.mouse_point_inside_square = nil
  end


  def calc_card_positions
    all_cards =
      @visible_ingredients
        .merge(@selected_ingredients)
        .merge(@visible_potions)

    all_moveable_cards =
      @visible_ingredients.merge(@selected_ingredients).merge(@visible_potions)

    all_moveable_cards.each do |id, c|
      c.calc_position(0, 0)
      if out_of_bounds?(c) && !$game.input_locked && !c.marked_for_removal
        c.mark_for_removal
        $AUDIO_SERVICE.play_sound(:remove_ingredient)
        unselect_cards(c)
      end
      other_card_rects =
        get_all_card_rects.reject { |other_c| other_c[:id] == c.entity_id }
      collision_rect = Geometry.find_intersect_rect(c.rect, other_card_rects)

      if collision_rect
        vec = {
          x: (collision_rect.x - c.rect.x),
          y: (collision_rect.y - c.rect.y)
        }
        dist =
          Geometry.distance(
            Geometry.rect_center_point(collision_rect),
            Geometry.rect_center_point(c.rect)
          )

        reverse_dist_formula = ((160 - (dist * 1.5)) / 2).clamp(0, 30)

        nvec = Geometry.vec2_normalize(vec)
        c.vx = nvec.x * -1 * reverse_dist_formula
        c.vy = nvec.y * -1 * reverse_dist_formula
      end
    end
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    cards ||= []
    sel_cards ||= []
    front_card = nil

    @visible_ingredients
      .merge(@visible_potions)
      .each do |id, c|
      prefab = c.prefab
      if GameUtils.is_potion(c)
        prefab = c.prefab
      else
        prefab, tooltip_prefab = c.prefab
      end
      if c.grabbed
        front_card = prefab
      else
        cards.append prefab
      end
    end

    @selected_ingredients.each do |id, c| 
      if GameUtils.is_potion(c)
        sel_cards.append(c.prefab)
      else
        prefab, tooltip_prefab = c.prefab
        sel_cards.append(prefab)
      end
    end

    tile_index = 0.frame_index(6, 0.25.seconds, true)
    bg_tile_index = 0.frame_index(24, 1.0.seconds, true)

    case layer_num
    when 0
      background_solid = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        r: 0,
        g: 0,
        b: 0,
        primitive_marker: :solid
      }
      background = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        r: 255,
        g: 255,
        b: 255,
        a: 80,
        path: "sprites/alchemy_table_bg.png"
      }

      l0 << [background_solid, background]

      l0
    when 1
      left_panel_a ||= {
        x: 0,
        y: 0,
        w: 128,
        h: GTK.args.grid.h,
        path: "sprites/sketchypanel02.png",
        tile_x: 0 + (tile_index * 200),
        tile_y: 0,
        tile_w: 200,
        tile_h: GTK.args.grid.h,
        primitive_marker: :sprite
      }

      right_panel_a ||= {
        x: GTK.args.grid.w - 128,
        y: 0,
        w: 128,
        h: GTK.args.grid.h,
        path: "sprites/sketchypanel02.png",
        tile_x: 0 + (tile_index * 200),
        tile_y: 0,
        tile_w: 200,
        tile_h: GTK.args.grid.h,
        primitive_marker: :sprite
      }

      l1 << [
        left_panel_a,
        right_panel_a,
        @ing_menu_widget.render,
        @pot_menu_widget.render
      ]
      l1
    when 2
      encounter_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 50,
        alignment_enum: 1,
        size_enum: 8,
        r: 255,
        g: 255,
        b: 255,
        text: "Brew Bench",
        primitive_marker: :label,
        font: $FONT
      }

      l2 << [
        encounter_label,
        @leave_btn.prefab,
        potions_label,
        ingredients_label,
        cards
      ]

      @selection_squares.each do |square|
        f_i =
          Numeric.frame_index(
            start_at: square.start_tick,
            count: 4,
            hold_for: 10,
            repeat: true
          )
        l2 << selection_square_prefab(
          x: square.card_to_follow.pos.x,
          y: square.card_to_follow.pos.y,
          f_i: f_i
        )
      end
      l2
    when 3
      l3 << [front_card, sel_cards]
      l3
    when 4
      l4 << [@brew_btn.prefab] if @craftable_potion

      uses_left_label ||= {
        x: 64,
        y: 48,
        alignment_enum: 1,
        size_px: 18,
        r: 255,
        g: 255,
        b: 255,
        text: "Brews Left: #{@uses_left}",
        font: $FONT,
        primitive_marker: :label
      }

      l4 << [uses_left_label]
      l4 << render_brew_anim
      l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def potions_label()
    sprite_frames = 6
    time_per_frame = 0.5.seconds
    repeat_index = true
    tile_index = 0.frame_index(sprite_frames, time_per_frame, repeat_index)

    prefabs = []

    prefabs << {
      x: GTK.args.grid.w - 96 - 16,
      y: GTK.args.grid.h - 96,
      w: 96,
      h: 64,
      path: "sprites/sketchymodal_162x114.png",
      tile_x: 0 + (tile_index * 162),
      tile_y: 0,
      tile_w: 162,
      tile_h: 114,
      primitive_marker: :sprite
    }

    prefabs << {
      x: GTK.args.grid.w - 64,
      y: GTK.args.grid.h - 56,
      text: "POTION",
      anchor_x: 0.5,
      anchor_y: 0.5,
      alignment_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      font: $FONT,
      size_px: 12
    }

    prefabs << {
      x: GTK.args.grid.w - 64,
      y: GTK.args.grid.h - 52 - 16,
      text: "SATCHEL",
      anchor_x: 0.5,
      anchor_y: 0.5,
      alignment_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      font: $FONT,
      size_px: 12
    }

    prefabs
  end

  def ingredients_label()
    sprite_frames = 6
    time_per_frame = 0.5.seconds
    repeat_index = true
    tile_index = 0.frame_index(sprite_frames, time_per_frame, repeat_index)

    prefabs = []

    prefabs << {
      x: 16,
      y: GTK.args.grid.h - 96,
      w: 96,
      h: 64,
      path: "sprites/sketchymodal_162x114.png",
      tile_x: 0 + (tile_index * 162),
      tile_y: 0,
      tile_w: 162,
      tile_h: 114,
      primitive_marker: :sprite
    }

    prefabs << {
      x: 64,
      y: GTK.args.grid.h - 56,
      text: "INGREDIENT",
      anchor_x: 0.5,
      anchor_y: 0.5,
      alignment_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      font: $FONT,
      size_px: 12
    }

    prefabs << {
      x: 64,
      y: GTK.args.grid.h - 52 - 16,
      text: "SATCHEL",
      anchor_x: 0.5,
      anchor_y: 0.5,
      alignment_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      font: $FONT,
      size_px: 12
    }

    prefabs
  end

  def get_card_rects
    rects = []
    @visible_ingredients
      .merge(@selected_ingredients)
      .merge(@visible_potions)
      .each do |id, card|
        r = card.rect.dup
        r[:id] = id
        rects << r
      end
    rects
  end

  def get_all_card_rects
    rects = []
    cards =
      @visible_ingredients
        .merge(@selected_ingredients)
        .merge(@visible_potions)

    cards.each do |id, card|
      r = card.rect.dup
      r[:id] = id
      rects << r
    end
    rects
  end

  def draw_card(card)
    return nil unless card

    @visible_ingredients[card.entity_id] = card if !GameUtils.is_potion(card.id)
    @visible_potions[card.entity_id] = card if GameUtils.is_potion(card.id)
    @ingredients_on_screen.add(card)
    card
  end

  def calc_mouse_inputs
    if @leave_btn.clicked?
      puts "clicked on leave_btn"
      leave
    end

    if @craftable_potion && @brew_btn.clicked?
      puts "clicked on craft_btn"
      play_brew_anim
    end

    if (clicked = @pot_menu_widget.selected_item)
      puts "Clicked: #{clicked.name}"
      potion_card = clicked
      refresh(clicked) if potion_card.uses_left < potion_card.max_uses
    end

    calc_card_drag_inputs
  end

  def calc_card_drag_inputs
    if state.currently_dragging_card_id
      id = state.currently_dragging_card_id
      c_ref =
        @visible_ingredients[id] || @selected_ingredients[id] ||
          @visible_potions[id]
    else
      c_u_m = Geometry.find_intersect_rect inputs.mouse, get_card_rects
      c_ref = nil
    end

    if clicked = @ing_menu_widget.pop_clicked
      puts "Clicked: #{clicked.name}"
      new_card = @ing_menu_widget.remove_item(clicked)
      $AUDIO_SERVICE.play_sound(:bag_remove)
      if new_card
        c_ref = draw_card(new_card)
        if c_ref
          c_ref.activation_time = Kernel.tick_count
          c_u_m = c_ref.rect
          c_ref.instant_set_position(
            x: GTK.args.inputs.mouse.x,
            y: GTK.args.inputs.mouse.y
          )
          c_u_m.x = GTK.args.inputs.mouse.x
          c_u_m.y = GTK.args.inputs.mouse.y
          c_ref.grab
        end
      end
      update_inventories
    end
    if inputs.mouse.click && c_u_m
      card_id = c_u_m[:id]
      state.currently_dragging_card_id = card_id
      c_ref =
        @visible_ingredients[card_id] || @selected_ingredients[card_id] ||
          @visible_potions[card_id]
      c_ref.grab
      calc_card_return(c_ref)

      reorder_cards(c_ref)

      state.mouse_point_inside_square = {
        x: inputs.mouse.x - c_u_m.x,
        y: inputs.mouse.y - c_u_m.y
      }
      state.click_hold_time = Kernel.tick_count
    elsif inputs.mouse.held && state.currently_dragging_card_id && c_ref
      c_ref.pos.x = inputs.mouse.x - state.mouse_point_inside_square.x
      c_ref.pos.y = inputs.mouse.y - state.mouse_point_inside_square.y
    elsif inputs.mouse.up && state.currently_dragging_card_id
      if state.click_hold_time.elapsed_time < 20 and
           (Geometry.distance c_ref.pos, c_ref.f_pos) < 20 and
           (c_ref.activation_time.elapsed_time > 0.25.seconds)
        use_card(c_ref)
      end

      if inputs.mouse.intersect_rect?(@ing_menu_widget.rect) and
           !@selected_ingredients.values.include?(c_ref) &&
             !GameUtils.is_potion(c_ref.id)
        @ing_menu_widget.add_item(c_ref)
        @visible_ingredients.reject! { |id, c| c == c_ref }
        $AUDIO_SERVICE.play_sound(:bag_insert)
        update_inventories
      end

      @visible_ingredients.reject! { |id, c| c.marked_for_removal && c.w <= 5 }
      @visible_potions.reject! { |id, c| c.marked_for_removal && c.w <= 5 }

      if inputs.mouse.intersect_rect?(@pot_menu_widget.rect) &&
           GameUtils.is_potion(c_ref.id)
        c_ref.free_floating = false
        @pot_menu_widget.add_item(c_ref)
        @visible_potions.reject! { |id, c| c == c_ref }
        $AUDIO_SERVICE.play_sound(:bag_insert)
        update_inventories
      end

      # Re-fetch the card from either group.
      if c_ref
        c_ref.f_pos.x = c_ref.pos.x
        c_ref.f_pos.y = c_ref.pos.y
        c_ref.grabbed = false
      end
      state.currently_dragging_card_id = nil
    end
  end

  def out_of_bounds?(card)
    !card.grabbed &&
      (
        card.pos.y < 100 || card.pos.y > GTK.args.grid.h - card.h ||
          card.pos.x < 128 || card.pos.x > GTK.args.grid.w - card.w - 128
      )
  end

  def use_card(c)
    puts "CALLED USE CARD"
    toggle_card_selected(c) if !GameUtils.is_potion(c.id)
    craftable_potion?

    if @from_tutorial && @craftable_potion && !@tutorial_steps[:recipe_selected]
      @tutorial_steps[:recipe_selected] = true
      $TUTORIAL_INDEX = 17
      id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
      GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
    end
  end

  def craftable_potion?
    @craftable_potion = @recipe_book.craftable_potion?(@selected_ingredients)
  end

  def unselect_cards(c = nil)
    if c
      move_card(c, @visible_ingredients, @selected_ingredients)
      remove_selection_square(followed_card: c)
    else
      @selected_ingredients.each { |id, c| toggle_card_selected(c) }
    end
  end

  def toggle_card_selected(c)
    if !c.selected
      $AUDIO_SERVICE.play_sound(:select_card)
      add_selection_square(card_to_follow: c)
      move_card(c, @selected_ingredients, @visible_ingredients)
      c.calc_render_target(GTK.args)
    else
      $AUDIO_SERVICE.play_sound(:unselect_card)
      remove_selection_square(followed_card: c)
      move_card(c, @visible_ingredients, @selected_ingredients)
      c.calc_render_target(GTK.args)
    end
  end
  
  def add_selection_square(card_to_follow:)
    @selection_squares << {
      card_to_follow: card_to_follow,
      start_tick: Numeric.rand(-180..0)
    }
  end
  
  def remove_selection_square(followed_card:)
    @selection_squares.reject! do |square|
      square.card_to_follow == followed_card
    end
  end
  
  def selection_square_prefab(x:, y:, f_i:)
    puts "FRAME_INDEX: #{f_i}"
    {
      x: x,
      y: y,
      anchor_x: 0.5,
      anchor_y: 0.5,
      w: 170,
      h: 170,
      a: 255,
      path: "sprites/selected_card_outline-sheet-4.png",
      tile_x: 1024 * f_i,
      tile_y: 0,
      tile_w: 1024,
      tile_h: 1024
    }
  end

  def move_card(c, to, from)
    to[c.entity_id] = c
    from.delete c.entity_id if from

    if to == @visible_ingredients && from == @selected_ingredients
      c.selected = false
      c.fw = 160
      c.fh = 160
      c.grabbed = false
      c.padding = -60.0
    elsif to == @selected_ingredients && from == @visible_ingredients
      c.selected = true
      c.fw = 250
      c.fh = 250
      c.grabbed = false
      c.padding = 5.0
    end

    craftable_potion?
  end

  def calc_keyboard_inputs
    return unless @craftable_potion and inputs.keyboard.key_down.space

    play_brew_anim
  end
  
  def reorder_cards(latest_card)
    if @visible_ingredients.key?(latest_card.entity_id)
      HashOrderUtils.back(@visible_ingredients, latest_card.entity_id)
    end
    if @selected_ingredients.key?(latest_card.entity_id)
      HashOrderUtils.back(@selected_ingredients, latest_card.entity_id)
    end
  end

  def update_inventories
    # gather all ingredient cards to return to the player's inventory
    new_ings = []

    if @ing_menu_widget.respond_to?(:items?)
      new_ings.concat(@ing_menu_widget.items?)
    else
      new_ings.concat(@ing_menu_widget.instance_variable_get(:@items))
    end
    # gather potions from the potion menu and any visible/selected potion stacks
    new_pots = []

    if @pot_menu_widget.respond_to?(:items?)
      new_pots.concat(@pot_menu_widget.items?)
    else
      new_pots.concat(@pot_menu_widget.instance_variable_get(:@items))
    end

    @player.ingredients = Inventory.new(new_ings)
    @player.potions = Inventory.new(new_pots)
  end
end
