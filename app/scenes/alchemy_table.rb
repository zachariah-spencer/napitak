# frozen_string_literal: true

class AlchemyTable
  attr_gtk
  attr :sc_id

  def initialize(max_uses:)
    @sc_id = "alchemy_table"
    @player = $player
    @recipe_book = $recipe_book
    @uses_left = max_uses
    @visible_ingredients = {}
    @selected_ingredients = {}
    @craftable_potion = nil

    @ing_menu_widget =
      ScrollListWidget.new(
        items: @player.ingredients.all_cards,
        x: 20,
        y: GTK.args.grid.h / 2 - 250,
        w: 160,
        h: 500,
        uid: 1
      )
    @pot_menu_widget =
      ScrollListWidget.new(
        items: @player.potions.all_cards,
        x: GTK.args.grid.w - 20 - 160,
        y: GTK.args.grid.h / 2 - 250,
        w: 160,
        h: 500,
        uid: 2
      )
  end

  def cleanup
    puts "cleanup alchemy_table.rb"

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
    if @recipe_book.can_craft?(recipe_id)
      potion = @recipe_book.craft(recipe_id)
      @selected_ingredients.clear

      if GameUtils.is_potion(potion.id)
        @pot_menu_widget.add_item(potion)
      else
        potion.f_pos.x = GTK.args.grid.w / 2 - (potion.w / 2)
        potion.f_pos.y = GTK.args.grid.h / 2 - (potion.h / 2)
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
    # consolidate all ingredient cards into the player's inventory
    new_cards = []

    # items still inside the vertical ingredient menu
    if @ing_menu_widget.respond_to?(:items?)
      new_cards.concat(@ing_menu_widget.items?)
    else
      new_cards.concat(@ing_menu_widget.instance_variable_get(:@items))
    end

    # cards currently on the table but not selected
    new_cards.concat(@visible_ingredients.values)

    # cards that are currently selected for crafting
    new_cards.concat(@selected_ingredients.values)

    # overwrite the player's ingredients with this collection
    @player.ingredients = Inventory.new(new_cards)

    $game.change_scene(prev_sc: @sc_id, next_sc: "map")
  end

  def tick
    @ing_menu_widget.tick(GTK.args.inputs)
    @pot_menu_widget.tick(GTK.args.inputs)
    calc
  end

  def calc
    calc_card_positions
    calc_mouse_inputs
    calc_keyboard_inputs
  end

  def calc_card_positions
    @visible_ingredients
      .merge(@selected_ingredients)
      .each_with_index do |(id, c), i|
        c.calc_position(@visible_ingredients.length, i)
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

    @visible_ingredients.each do |id, c|
      prefab = c.prefab

      if c.grabbed
        front_card = prefab
      else
        cards.append prefab
      end
    end

    @selected_ingredients.each { |id, c| sel_cards.append(c.prefab) }

    case layer_num
    when 0
      background ||= {
        x: 0,
        y: 0,
        w: GTK.args.grid.w,
        h: GTK.args.grid.h,
        r: 10,
        g: 10,
        b: 20,
        primitive_marker: :solid
      }

      l0 << [background]

      l0
    when 1
      left_panel ||= {
        x: 0,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        r: 50,
        g: 50,
        b: 50,
        a: 50,
        primitive_marker: :solid
      }

      right_panel ||= {
        x: GTK.args.grid.w - 200,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        r: 50,
        g: 50,
        b: 50,
        a: 50,
        primitive_marker: :solid
      }

      l1 << [left_panel, right_panel, @ing_menu_widget.render, @pot_menu_widget.render, ]
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
        text: "Alchemy Table",
        primitive_marker: :label
      }

      l2 << [
        encounter_label,
        leave_btn,
        potions_label,
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
          primitive_marker: :label
        }

        l4 << [craftable_potion_label, craft_btn]
      end

      uses_left_label ||= {
        x: GTK.args.grid.w / 2,
        y: 50,
        alignment_enum: 1,
        size_enum: 8,
        r: 255,
        g: 255,
        b: 255,
        text: "Brewing Capacity: #{@uses_left}",
        primitive_marker: :label
      }

      l4 << [uses_left_label]
      l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
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
      size_enum: 3
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

  def potions_label
    GTK.args.outputs[:potions_label].w = 150
    GTK.args.outputs[:potions_label].h = 75

    GTK.args.outputs[:potions_label].primitives << {
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

    GTK.args.outputs[:potions_label].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 180,
      g: 50,
      b: 50,
      primitive_marker: :solid
    }

    GTK.args.outputs[:potions_label].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "POTIONS",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 0,
      g: 0,
      b: 0,
      size_enum: 3
    }

    {
      x: GTK.args.grid.w - 25 - 150,
      y: GTK.args.grid.h - 20 - 75,
      w: 150,
      h: 75,
      angle: 0,
      path: :potions_label,
      primitive_marker: :sprite
    }
  end

  def ingredients_label
    GTK.args.outputs[:ingredients_label].w = 150
    GTK.args.outputs[:ingredients_label].h = 75

    GTK.args.outputs[:ingredients_label].primitives << {
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

    GTK.args.outputs[:ingredients_label].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 180,
      g: 50,
      b: 50,
      primitive_marker: :solid
    }

    GTK.args.outputs[:ingredients_label].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "INGREDIENTS",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 0,
      g: 0,
      b: 0,
      size_enum: 3
    }

    {
      x: 25,
      y: GTK.args.grid.h - 20 - 75,
      w: 150,
      h: 75,
      angle: 0,
      path: :ingredients_label,
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

  def get_card_rects
    rects = []
    @visible_ingredients
      .merge(@selected_ingredients)
      .each do |id, card|
        rects << {
          x: card.pos.x,
          y: card.pos.y,
          w: card.fw,
          h: card.fh,
          id: id
        }
      end
    rects
  end

  def draw_card(card)
    return nil unless card

    @visible_ingredients[card.entity_id] = card
    card
  end

  def calc_mouse_inputs
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
      c_ref = @visible_ingredients[id] || @selected_ingredients[id]
    else
      c_u_m = Geometry.find_intersect_rect inputs.mouse, get_card_rects
      c_ref = nil
    end

    if clicked = @ing_menu_widget.pop_clicked
      puts "Clicked: #{clicked.name}"
      new_card = @ing_menu_widget.remove_item(clicked)
      if new_card
        c_ref = draw_card(new_card)
        if c_ref
          c_ref.activation_time = Kernel.tick_count
          c_u_m = c_ref.rect
          c_u_m.x = GTK.args.inputs.mouse.x - 80
          c_u_m.y = GTK.args.inputs.mouse.y - 80
          c_ref.grabbed = true
        end
      end
    end

    if inputs.mouse.click and c_u_m
      card_id = c_u_m[:id]
      state.currently_dragging_card_id = card_id
      c_ref = @visible_ingredients[card_id] || @selected_ingredients[card_id]
      c_ref.grabbed = true

      state.mouse_point_inside_square = {
        x: inputs.mouse.x - c_u_m.x,
        y: inputs.mouse.y - c_u_m.y
      }
      state.click_hold_time = Kernel.tick_count
    elsif inputs.mouse.held and state.currently_dragging_card_id
      c_ref.pos.x = inputs.mouse.x - state.mouse_point_inside_square.x
      c_ref.pos.y = inputs.mouse.y - state.mouse_point_inside_square.y
    elsif inputs.mouse.up and state.currently_dragging_card_id
      if state.click_hold_time.elapsed_time < 20 and
           (Geometry.distance c_ref.pos, c_ref.f_pos) < 20 and
           (c_ref.activation_time.elapsed_time > 0.25.seconds)
        use_card(c_ref)
      end

      if inputs.mouse.intersect_rect?(@ing_menu_widget.rect)
        @ing_menu_widget.add_item(c_ref)
        @visible_ingredients.reject! { |id, c| c == c_ref }
      end

      # Re-fetch the card from either group.
      c_ref.f_pos.x = c_ref.pos.x
      c_ref.f_pos.y = c_ref.pos.y
      c_ref.grabbed = false
      state.currently_dragging_card_id = nil
    end
  end

  def use_card(c)
    puts "CALLED USE CARD"
    toggle_card_selected(c)
    @craftable_potion = @recipe_book.craftable_potion?(@selected_ingredients)
  end

  def unselect_cards
    @selected_ingredients.each { |id, c| toggle_card_selected(c) }
  end

  def toggle_card_selected(c)
    if !c.selected
      move_card(c, @selected_ingredients, @visible_ingredients)
    else
      move_card(c, @visible_ingredients, @selected_ingredients)
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
end
