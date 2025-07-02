# frozen_string_literal: true

class AlchemyLab
  attr_gtk
  attr :sc_id

  def initialize(max_uses:, max_ingredients:, tutorial: false)
    @sc_id = "alchemy_lab"
    @player = $player
    @recipe_book = $recipe_book
    @uses_left = max_uses
    @max_ingredients = max_ingredients
    @visible_ingredients = {}
    @selected_ingredients = {}
    @visible_potions = {}
    @ingredient_generators = {}
    @ingredients_on_screen = Inventory.new()
    @craftable_potion = nil

    padding = 40
    card_size = 80
    start_x =
      GTK.args.grid.w / 2 -
        (((padding + card_size) / 2) * @recipe_book.unlocked_bases.size)
    @recipe_book.unlocked_bases.each_with_index do |base_id, i|
      c = IngredientGeneratorCard.new(base_id)
      c.instant_set_position(x: start_x + (i * (padding + card_size)), y: 20)
      @ingredient_generators[c.id] = c

      @trash_can = TrashCanCard.new()
      @trash_can.instant_set_position(
        x: GTK.args.grid.w - 300,
        y: GTK.args.grid.h - 100
      )
    end

    @ing_menu_widget =
      ScrollListWidget.new(
        items: [],
        x: 20,
        y: GTK.args.grid.h / 2 - 270,
        w: 160,
        h: 500
      )
    @pot_menu_widget =
      ScrollListWidget.new(
        items: [],
        x: GTK.args.grid.w - 20 - 160,
        y: GTK.args.grid.h / 2 - 270,
        w: 160,
        h: 500
      )

    @prev_loadout_btn =
      Button.new(
        x: 300,
        y: GTK.args.grid.h - 100,
        w: 150,
        h: 75,
        text: "Prev. Loadout"
      )
  end

  def cleanup
    puts "cleanup alchemy_lab.rb"
    state.currently_dragging_card_id = nil
    state.mouse_point_inside_square = nil

    potions_save_data = []
    @player.potions.all_cards.each { |c| potions_save_data << c.save_data? }

    ingredients_save_data = []
    @player.ingredients.all_cards.each do |c|
      ingredients_save_data << c.save_data?
    end

    # previous_starting_potions_config, previous_starting_ingredients_config = @player.get_inventory_save_data
    $player.prev_loadout_potions = Inventory.new(@pot_menu_widget.items?)
    $player.prev_loadout_ingredients = Inventory.new(@ing_menu_widget.items?)

    $files.save_data["player"]["potions"] = potions_save_data
    $files.save_data["player"]["ingredients"] = ingredients_save_data
    $files.save_data["player"]["previous_run_potions"] = potions_save_data
    $files.save_data["player"][
      "previous_run_ingredients"
    ] = ingredients_save_data
    $files.write
  end

  def craft(recipe_id)
    if @recipe_book.can_craft?(
         recipe_id,
         ingredients_inventory: @ingredients_on_screen.all_cards
       )
      potion =
        @recipe_book.craft(
          recipe_id,
          ingredients_inventory: @ingredients_on_screen.all_cards
        )
      @selected_ingredients.clear

      if GameUtils.is_potion(potion.id)
        @pot_menu_widget.add_item(potion)
      else
        potion.instant_set_position(
          x: GTK.args.grid.w / 2 - (potion.w / 2),
          y: GTK.args.grid.h / 2 - (potion.h / 2)
        )
        @visible_ingredients[potion.entity_id] = potion
        @ingredients_on_screen.add(potion)
      end

      puts "CRAFTED #{potion.name}"

      update_uses_left
    else
      puts "CANNOT CRAFT #{recipe_id}"
    end
  end

  def refresh(potion_card)
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

  def leave
    # consolidate all new cards into the player's inventory
    new_ings = []
    new_pots = []

    if @pot_menu_widget.respond_to?(:items?)
      new_pots.concat(@pot_menu_widget.items?)
    else
      new_pots.concat(@pot_menu_widget.instance_variable_get(:@items))
    end

    # items still inside the vertical ingredient menu
    if @ing_menu_widget.respond_to?(:items?)
      new_ings.concat(@ing_menu_widget.items?)
    else
      new_new_ings.concat(@ing_menu_widget.instance_variable_get(:@items))
    end

    # overwrite the player's potions with this collection
    @player.potions = Inventory.new(new_pots)
    # overwrite the player's ingredients with this collection
    @player.ingredients = Inventory.new(new_ings)

    $encounter_manager.inc_encounters_completed

    $game.change_scene(prev_sc: @sc_id, next_sc: "map")
  end

  def tick
    @ing_menu_widget.tick(GTK.args.inputs)
    @pot_menu_widget.tick(GTK.args.inputs)
    @ingredient_generators.each { |id, c| c.tick }
    @trash_can.tick
    calc
  end

  def calc
    if !$game.input_locked
      calc_keyboard_inputs
      calc_mouse_inputs
    else
      calc_inputs_locked
    end

    calc_card_positions
  end

  def calc_inputs_locked
    all_moveable_cards =
      @visible_ingredients.merge(@selected_ingredients).merge(@visible_potions)

    all_moveable_cards.each { |id, c| c.grabbed = false }

    state.currently_dragging_card_id = nil
    state.mouse_point_inside_square = nil
  end

  def clear_loadout
    @selected_ingredients.clear
    @visible_ingredients.clear
    @visible_potions.clear
    @ing_menu_widget.clear_items
    @pot_menu_widget.clear_items
  end

  def config_prev_loadout
    $player.prev_loadout_potions.all_cards.each do |card|
      @pot_menu_widget.add_item(card)
    end
    $player.prev_loadout_ingredients.all_cards.each do |card|
      @ing_menu_widget.add_item(card)
    end
  end

  def calc_card_positions
    all_cards =
      @visible_ingredients
        .merge(@selected_ingredients)
        .merge(@visible_potions)
        .merge(@ingredient_generators)

    all_moveable_cards =
      @visible_ingredients.merge(@selected_ingredients).merge(@visible_potions)

    all_cards[@trash_can.id] = @trash_can

    all_moveable_cards.each do |id, c|
      c.calc_position(0, 0)
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

        reverse_dist_formula = ((160 - (dist * 1.3)) / 4).clamp(0, 30)

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
    generator_cards ||= []
    front_card = nil

    @visible_ingredients
      .merge(@visible_potions)
      .each do |id, c|
        prefab = c.prefab
        if c.grabbed
          front_card = prefab
        else
          cards.append prefab
        end
      end
    @selected_ingredients.each { |id, c| sel_cards.append(c.prefab) }
    @ingredient_generators.each { |id, c| generator_cards.append(c.prefab) }

    tile_index = 0.frame_index(6, 0.25.seconds, true)
    bg_tile_index = 0.frame_index(24, 1.0.seconds, true)

    case layer_num
    when 0
      background = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        r: 50,
        g: 50,
        b: 50,
        path:
          "sprites/background_frames/sketchybackground#{bg_tile_index + 1}.png"
      }

      l0 << [background]

      l0
    when 1
      left_panel_a ||= {
        x: 0,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        path: "sprites/sketchypanel02.png",
        tile_x: 0 + (tile_index * 200),
        tile_y: 0,
        tile_w: 200,
        tile_h: GTK.args.grid.h,
        primitive_marker: :sprite
      }

      right_panel_a ||= {
        x: GTK.args.grid.w - 200,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        path: "sprites/sketchypanel02.png",
        tile_x: 0 + (tile_index * 200),
        tile_y: 0,
        tile_w: 200,
        tile_h: GTK.args.grid.h,
        primitive_marker: :sprite
      }

      low_panel_debug ||= {
        x: 0,
        y: 0,
        w: GTK.args.grid.w,
        h: 110,
        r: 50,
        g: 50,
        b: 50,
        a: 200,
        primitive_marker: :solid
      }

      l1 << [low_panel_debug, left_panel_a, right_panel_a]
      # l1 << [ left_panel_b, right_panel_b,]
      l1 << [
        @ing_menu_widget.render,
        @pot_menu_widget.render,
        generator_cards,
        @trash_can.prefab
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
        text: "Alchemy Lab",
        font: "fonts/eaglelake.ttf",
        primitive_marker: :label
      }

      if $player.prev_loadout_potions.all_cards.size > 0 ||
           $player.prev_loadout_ingredients.all_cards.size > 0
        l2 << @prev_loadout_btn.prefab
      end

      l2 << [
        encounter_label,
        leave_btn,
        potions_label(),
        ingredients_label,
        cards
      ]
      l2
    when 3
      l3 << [front_card, sel_cards]
      l3
    when 4
      if @craftable_potion
        craftable_potion_label ||= {
          x: GTK.args.grid.w / 2,
          y: GTK.args.grid.h / 2 + 150,
          text: "#{@craftable_potion.data.name}",
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 255,
          g: 0,
          b: 0,
          size_enum: 15,
          font: "fonts/eaglelake.ttf",
          primitive_marker: :label
        }

        l4 << [craftable_potion_label, craft_btn]
      end

      uses_left_label ||= {
        x: GTK.args.grid.w / 2,
        y: 150,
        alignment_enum: 1,
        size_enum: 8,
        r: 255,
        g: 255,
        b: 255,
        text: "Brewing Capacity: #{@uses_left}",
        font: "fonts/eaglelake.ttf",
        primitive_marker: :label
      }

      ingredients_stored_label ||= {
        x: 100,
        y: 75,
        alignment_enum: 1,
        size_enum: 8,
        r: 255,
        g: 255,
        b: 255,
        text: "#{@ing_menu_widget.items?.size} / #{@max_ingredients}",
        font: "fonts/eaglelake.ttf",
        primitive_marker: :label
      }

      l4 << [uses_left_label, ingredients_stored_label]

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
      x: GTK.args.grid.w - 162 - 16,
      y: GTK.args.grid.h - (114) - (16 * 1.5),
      w: 162,
      h: 114,
      path: "sprites/sketchymodal_162x114.png",
      tile_x: 0 + (tile_index * 162),
      tile_y: 0,
      tile_w: 162,
      tile_h: 114,
      primitive_marker: :sprite
    }

    prefabs << {
      x: GTK.args.grid.w - 162 - 12 + (162 / 2),
      y: GTK.args.grid.h - (114) - (16 * 1.5) + (114 / 2) + 5,
      text: "POTIONS",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      font: "fonts/eaglelake.ttf",
      size_px: 20
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
      y: GTK.args.grid.h - (114) - (16 * 1.5),
      w: 162,
      h: 114,
      path: "sprites/sketchymodal_162x114.png",
      tile_x: 0 + (tile_index * 162),
      tile_y: 0,
      tile_w: 162,
      tile_h: 114,
      primitive_marker: :sprite
    }

    prefabs << {
      x: 100,
      y: GTK.args.grid.h - (114) - (16 * 1.5) + (114 / 2) + 5,
      text: "INGREDIENTS",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      font: "fonts/eaglelake.ttf",
      size_px: 20
    }

    prefabs
  end

  def craft_btn
    GTK.args.outputs[:craft_btn].w = 150
    GTK.args.outputs[:craft_btn].h = 75

    GTK.args.outputs[:craft_btn].primitives << {
      x: 0,
      y: 0,
      w: 150,
      h: 75,
      angle: 0,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    }

    GTK.args.outputs[:craft_btn].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 70,
      g: 70,
      b: 150,
      a: 100,
      primitive_marker: :solid
    }

    GTK.args.outputs[:craft_btn].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "CRAFT",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 3,
      font: "fonts/eaglelake.ttf"
    }

    {
      x: GTK.args.grid.w / 2 - 75,
      y: GTK.args.grid.h - 75 - 100,
      w: 150,
      h: 75,
      angle: 0,
      path: :craft_btn,
      primitive_marker: :sprite
    }
  end

  def leave_btn
    GTK.args.outputs[:leave_btn].w = 150
    GTK.args.outputs[:leave_btn].h = 75

    GTK.args.outputs[:leave_btn].primitives << {
      x: 0,
      y: 0,
      w: 150,
      h: 75,
      angle: 0,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    }

    GTK.args.outputs[:leave_btn].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 100,
      g: 150,
      b: 150,
      primitive_marker: :solid
    }

    GTK.args.outputs[:leave_btn].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "LEAVE",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 0,
      g: 0,
      b: 0,
      size_enum: 3
    }

    {
      x: GTK.args.grid.w - 25 - 150,
      y: 20,
      w: 150,
      h: 75,
      angle: 0,
      path: :leave_btn,
      primitive_marker: :sprite
    }
  end

  def get_all_card_rects
    rects = []
    cards =
      @visible_ingredients
        .merge(@selected_ingredients)
        .merge(@visible_potions)
        .merge(@ingredient_generators)

    cards[@trash_can.id] = @trash_can

    cards.each do |id, card|
      rects << { x: card.pos.x, y: card.pos.y, w: card.w, h: card.h, id: id }
    end
    rects
  end

  def get_card_rects
    rects = []
    @visible_ingredients
      .merge(@selected_ingredients)
      .merge(@visible_potions)
      .each do |id, card|
        rects << { x: card.pos.x, y: card.pos.y, w: card.w, h: card.h, id: id }
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
    if @prev_loadout_btn.clicked? &&
         (
           $player.prev_loadout_potions.all_cards.size > 0 ||
             $player.prev_loadout_ingredients.all_cards.size > 0
         )
      clear_loadout
      config_prev_loadout
    end

    if GTK.args.inputs.mouse.click &&
         Geometry.intersect_rect?(inputs.mouse, leave_btn)
      puts "clicked on leave_btn"
      leave
    end

    if GTK.args.inputs.mouse.click &&
         Geometry.intersect_rect?(inputs.mouse, craft_btn) && @craftable_potion
      puts "clicked on craft_btn"
      craft(@craftable_potion.id)
      @craftable_potion = nil
    end

    if clicked = @pot_menu_widget.selected_item
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

    # try to pop a clicked ingredient from the ing_menu
    if clicked = @pot_menu_widget.pop_clicked
      puts "Clicked: #{clicked.name}"
      new_card = @pot_menu_widget.remove_item(clicked)
      puts new_card
      if new_card
        c_ref = draw_card(new_card)
        if c_ref
          c_ref.free_floating = true
          c_ref.activation_time = Kernel.tick_count
          c_u_m = c_ref.rect
          c_ref.instant_set_position(
            x: GTK.args.inputs.mouse.x - 80,
            y: GTK.args.inputs.mouse.y - 80
          )
          c_u_m.x = GTK.args.inputs.mouse.x - 80
          c_u_m.y = GTK.args.inputs.mouse.y - 80
          c_ref.grabbed = true
        end
      end
    end

    # try to pop a clicked ingredient from the ing_menu
    if clicked = @ing_menu_widget.pop_clicked
      puts "Clicked: #{clicked.name}"
      new_card = @ing_menu_widget.remove_item(clicked)
      if new_card
        c_ref = draw_card(new_card)
        if c_ref
          c_ref.activation_time = Kernel.tick_count
          c_u_m = c_ref.rect
          c_ref.instant_set_position(
            x: GTK.args.inputs.mouse.x - 80,
            y: GTK.args.inputs.mouse.y - 80
          )
          c_u_m.x = GTK.args.inputs.mouse.x - 80
          c_u_m.y = GTK.args.inputs.mouse.y - 80
          c_ref.grabbed = true
        end
      end
    end

    @ingredient_generators.each do |id, c|
      if clicked = c.pop_clicked
        puts "YOU CLICKED: #{clicked}"
        c_ref = GameUtils.gen_new_card(clicked[:id])
        puts c_ref
        if c_ref
          c_ref.activation_time = Kernel.tick_count
          c_u_m = c_ref.rect
          c_ref.instant_set_position(
            x: GTK.args.inputs.mouse.x - 80,
            y: GTK.args.inputs.mouse.y - 80
          )
          c_u_m.x = GTK.args.inputs.mouse.x - 80
          c_u_m.y = GTK.args.inputs.mouse.y - 80
          c_ref.grabbed = true
          draw_card(c_ref)
        end
      end
    end

    if inputs.mouse.click && c_u_m
      card_id = c_u_m[:id]
      state.currently_dragging_card_id = card_id
      c_ref =
        @visible_ingredients[card_id] || @selected_ingredients[card_id] ||
          @visible_potions[card_id]
      c_ref.grabbed = true

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
           @ing_menu_widget.items?.count < @max_ingredients and
           !@selected_ingredients.values.include?(c_ref) &&
             !GameUtils.is_potion(c_ref.id)
        @ing_menu_widget.add_item(c_ref)
        @visible_ingredients.reject! { |id, c| c == c_ref }
      end

      if inputs.mouse.intersect_rect?(@trash_can.rect)
        @visible_ingredients.reject! { |id, c| c == c_ref }
        @visible_potions.reject! { |id, c| c == c_ref }
      end

      if inputs.mouse.intersect_rect?(@pot_menu_widget.rect) &&
           GameUtils.is_potion(c_ref.id)
        @pot_menu_widget.add_item(c_ref)
        c_ref.free_floating = false
        @visible_potions.reject! { |id, c| c == c_ref }
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

  def use_card(c)
    puts "CALLED USE CARD"
    toggle_card_selected(c) if !GameUtils.is_potion(c.id)
    @craftable_potion = @recipe_book.craftable_potion?(@selected_ingredients)
  end

  def unselect_cards
    @selected_ingredients.each { |id, c| toggle_card_selected(c) }
  end

  def toggle_card_selected(c)
    if !GameUtils.is_potion(c)
      if !c.selected
        move_card(c, @selected_ingredients, @visible_ingredients)
      else
        move_card(c, @visible_ingredients, @selected_ingredients)
      end
    end
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
  end

  def calc_keyboard_inputs
    return unless @craftable_potion and inputs.keyboard.key_down.space

    craft(@craftable_potion.id)
    @craftable_potion = nil
  end

  def reorder_cards(latest_card)
    if @visible_ingredients.key?(latest_card.entity_id)
      HashOrderUtils.back(@visible_ingredients, latest_card.entity_id)
    end
    if @selected_ingredients.key?(latest_card.entity_id)
      HashOrderUtils.back(@selected_ingredients, latest_card.entity_id)
    end
  end
end
