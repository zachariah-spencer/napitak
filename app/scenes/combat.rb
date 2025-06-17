class Combat
  attr_gtk
  attr :sc_id

  def initialize
    @sc_id = "combat"
    @turn_stages = {
      drawing_cards: 0,
      playing_hand: 1,
      cleanup: 2,
      enemy_turn: 3
    }
    @hand = {}
    @matching_potion = nil
    @max_hand_size = 8
    @turn_stage = nil
    @turn_num = -1
    @player = $player
    @enemy = Enemy.new(10)
    @banner_alpha = 0
    @defeat_banner_timer = nil
    @victory_banner_timer = nil

    begin_combat
  end

  def tick
    calc
    @enemy.tick
    leave(true) if @victory_banner_timer&.elapsed_time == 3.seconds and @enemy.combat_stats.dead
    leave(false) if @defeat_banner_timer&.elapsed_time == 3.seconds and @player.combat_stats.dead
  end

  def calc_enemy_turn_ended
    if @player.combat_stats.dead
      @defeat_banner_timer = Kernel.tick_count
    else
      begin_turn_stage @turn_stages[:drawing_cards]
    end
  end

  def leave(is_victory = true)
    if is_victory
      $game.change_scene(prev_sc: @sc_id, next_sc: "rewards_screen")
    else
      $game.change_scene(prev_sc: "combat", next_sc: "run_summary")
    end
  end

  def calc
    calc_card_positions
    calc_mouse_inputs if @player.my_turn?
    calc_enemy_turn_ended if @enemy.turn_over?
    calc_entity_removals
    @banner_alpha = @banner_alpha.lerp(255, 0.02) if @defeat_banner_timer or @victory_banner_timer
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    cards ||= []
    front_card = []

    @hand.each do |id, c|
      c.grabbed ? front_card << c.prefab : cards << c.prefab
    end

    range = 255 - 0
    x = (Kernel.tick_count * 10) % (2 * range)
    osc_val = range - (x - range).abs

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
      return l0
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

      player_hp_label_header ||= {
        x: 100,
        y: GTK.args.grid.h - 225,
        alignment_enum: 1,
        size_enum: 8,
        r: 255,
        g: 255,
        b: 255,
        text: "HP",
        primitive_marker: :label
      }

      player_hp_label ||= {
        x: 100,
        y: GTK.args.grid.h - 275,
        alignment_enum: 1,
        size_enum: 8,
        r: 0,
        g: 150,
        b: 0,
        text: "#{@player.combat_stats.hp}/#{@player.combat_stats.max_hp}",
        primitive_marker: :label
      }

      player_focus_label_header ||= {
        x: 100,
        y: GTK.args.grid.h - 125,
        alignment_enum: 1,
        size_enum: 8,
        r: 255,
        g: 255,
        b: 255,
        text: "FOCUS",
        primitive_marker: :label
      }

      player_focus_label ||= {
        x: 100,
        y: GTK.args.grid.h - 175,
        alignment_enum: 1,
        size_enum: 8,
        r: 0,
        g: 150,
        b: 150,
        text: "#{@player.combat_stats.focus}",
        primitive_marker: :label
      }

      l1 << [
        left_panel,
        @enemy.render(1),
        player_hp_label_header,
        player_hp_label,
        player_focus_label_header,
        player_focus_label
      ]
      return l1
    when 2
      deck_sprite ||= {
        x: 20,
        y: 20,
        w: 160,
        h: 160,
        r: 80,
        g: 20,
        b: 80,
        primitive_marker: :solid
      }

      deck_card_count_label ||= {
        text: "#{@player.potions.size}",
        x: 100,
        y: 100,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_enum: 10,
        r: 255,
        g: 255,
        b: 255,
        primitive_marker: :label
      }

      discards_sprite ||= {
        x: 20,
        y: 200,
        w: 160,
        h: 160,
        r: 40,
        g: 40,
        b: 90,
        primitive_marker: :solid
      }

      discards_card_count_label ||= {
        text: "#{@player.potions.discard_size}",
        x: 100,
        y: 280,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_enum: 10,
        r: 255,
        g: 255,
        b: 255,
        primitive_marker: :label
      }

      pass_button ||= {
        x: 20,
        y: GTK.args.grid.h - 50 - (60 / 2),
        w: 160,
        h: 60,
        r: 100,
        g: 20,
        b: 20,
        primitive_marker: :solid
      }

      if @player.combat_stats.focus == @player.combat_stats.mod_max_focus
        pass_btn_text = "PASS"
        pass_btn_size = 10
      else
        pass_btn_text = "NEXT TURN"
        pass_btn_size = 5
      end

      pass_button_label ||= {
        x: 20 + (pass_button.w / 2),
        y: GTK.args.grid.h - 50,
        text: "#{pass_btn_text}",
        size_enum: pass_btn_size,
        alignment_enum: 1,
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255,
        primitive_marker: :label
      }

      players_turn_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2,
        size_enum: 10,
        r: 255,
        g: 255,
        b: 255,
        a: osc_val,
        alignment_enum: 1,
        text: "YOUR TURN"
      }

      l2 << players_turn_label if @player.my_turn?

      l2 << [
        deck_sprite,
        deck_card_count_label,
        discards_sprite,
        discards_card_count_label,
        pass_button,
        pass_button_label,
        cards
      ]
      return l2
    when 3
      l3 << [front_card]
      return l3
    when 4
      if @defeat_banner_timer
        defeat_banner_label ||= {
          x: GTK.args.grid.w / 2,
          y: GTK.args.grid.h / 2,
          alignment_enum: 1,
          anchor_x: 0.5,
          anchor_y: 0.5,
          size_enum: 20,
          r: 255,
          g: 255,
          b: 255,
          a: @banner_alpha,
          text: "DEFEAT",
          primitive_marker: :label
        }

        defeat_banner ||= {
          x: 0,
          y: GTK.args.grid.h / 2 - 100,
          w: GTK.args.grid.w,
          h: 200,
          r: 150,
          g: 0,
          b: 0,
          a: @banner_alpha,
          primitive_marker: :solid
        }

        l4 << [defeat_banner, defeat_banner_label]
      end

      if @victory_banner_timer
        victory_banner_label ||= {
          x: GTK.args.grid.w / 2,
          y: GTK.args.grid.h / 2,
          alignment_enum: 1,
          anchor_x: 0.5,
          anchor_y: 0.5,
          size_enum: 20,
          r: 255,
          g: 255,
          b: 255,
          a: @banner_alpha,
          text: "VICTORY",
          primitive_marker: :label
        }

        victory_banner ||= {
          x: 0,
          y: GTK.args.grid.h / 2 - 100,
          w: GTK.args.grid.w,
          h: 200,
          r: 0,
          g: 150,
          b: 0,
          a: @banner_alpha,
          primitive_marker: :solid
        }

        l4 << [victory_banner, victory_banner_label]
      end

      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def cleanup
    puts "cleanup combat.rb"
    @hand.each { |id, c| @player.potions.add(c) }

    potions_save_data = []
    @player.potions.all_cards.each { |c| potions_save_data << c.save_data? }

    $files.save_data["player"]["potions"] = potions_save_data
  end

  def calc_card_positions
    @hand.each_with_index do |(id, c), i|
      c.calc_position(@hand.length, i)
      c.tick()
    end
  end

  def calc_status_effects(type:)
    @player.combat_stats.calc_status(type: type)
    @enemy.combat_stats.calc_status(type: type)
  end

  def calc_entity_removals
    @hand.reject! { |id, c| c.needs_removed }
  end

  def calc_mouse_inputs
    return if $animation_manager&.input_locked?

    if state.currently_dragging_card_id
      c_ref = @hand[state.currently_dragging_card_id]
    else
      #card_under_mouse lol
      c_u_m = Geometry.find_intersect_rect inputs.mouse, get_card_rects
      c_ref = nil
    end

    @player.hovered_cards =
      Geometry.find_all_intersect_rect inputs.mouse, get_card_rects

    if inputs.mouse.click
      if Geometry.intersect_rect? inputs.mouse, get_deck_rect and
           @turn_stage == @turn_stages[:drawing_cards]
        puts "clicked on deck"
      elsif Geometry.intersect_rect? inputs.mouse, get_pass_button_rect and
            @turn_stage == @turn_stages[:playing_cards]
        begin_turn_stage @turn_stages[:cleanup]
      end
    end

    if @turn_stage == @turn_stages[:playing_cards]
      if inputs.mouse.click and c_u_m
        state.currently_dragging_card_id = c_u_m.id
        c_ref = @hand[state.currently_dragging_card_id]
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
        # Re-fetch the card from either group.
        c_ref.grabbed = false
        c_ref = @hand[state.currently_dragging_card_id]

        if state.click_hold_time.elapsed_time < 20 and
             (Geometry.distance c_ref.pos, c_ref.f_pos) < 20
          use_card c_ref
        end

        # For active hand cards, perform reordering.
        if @hand.key?(state.currently_dragging_card_id)
          # Exclude the dragged card from the current order.
          other_cards =
            @hand.values.reject do |card|
              card.entity_id == state.currently_dragging_card_id
            end
          sorted_ids =
            other_cards
              .sort_by { |card| card.pos.x }
              .map { |card| card.entity_id }

          # Calculate the center position of the dragged card.
          dragged_center = c_ref.pos[:x] + (c_ref.w / 2)

          # Determine where to insert the dragged card.
          new_index =
            sorted_ids.find_index do |card_id|
              card = @hand[card_id]
              dragged_center < (card.pos.x + (card.w / 2))
            end
          new_index ||= sorted_ids.length
          sorted_ids.insert(new_index, state.currently_dragging_card_id)

          # Rebuild the active hand from these sorted IDs.
          @hand = sorted_ids.map { |id| [id, @hand[id]] }.to_h
        end

        state.currently_dragging_card_id = nil
      end
    end
  end

  def skip_turn
    begin_turn_stage(@turn_stages[:enemy_turn])
  end

  def begin_turn_stage(new_stage)
    # new stage is of the format -> @turn_stages[:stage_symbol]
    @turn_stage = new_stage

    if new_stage == @turn_stages[:drawing_cards]
      puts "start drawing_cards stage"
      @player.potions.check_for_reshuffle
      if @player.stunned_turns > 0
        skip_turn
        @player.stunned_turns -= 1
        return
      end
      @player.begin_turn
      @turn_num += 1
      calc_status_effects(type:"BLIGHT")
      draw_card
      begin_turn_stage @turn_stages[:playing_cards]

    elsif new_stage == @turn_stages[:playing_cards]
      puts "start playing_cards stage"

    elsif new_stage == @turn_stages[:cleanup]
      puts "start cleanup stage"
      @player.my_turn = false
      calc_status_effects(type:"SCORCH")
      begin_turn_stage @turn_stages[:enemy_turn]

    elsif new_stage == @turn_stages[:enemy_turn]
      @enemy.begin_turn

    end
  end

  def draw_card
    if @player.potions.all_cards.size > 0
      card = @player.potions.draw
      puts card
      @hand[card.entity_id] = card
    end
  end

  def actions_available?
    return true if (@player.combat_stats.focus > 0 and @hand.length >= 1)
  end

  def use_card(card)
    potion_info = $pids[card.id]
    # handle deducting potion throwing focus cost
    if @player.combat_stats.focus >= potion_info.fc and card.uses_left > 0
      @player.combat_stats.focus -= potion_info.fc
      card.uses_left -= 1
      card.update_sprite()
      @player.potions.discard card
      @hand.delete card.entity_id

      # handle potion card behavior
      damage_trait =
        potion_info
          .traits
          .find { |h| h.key?($traits[:damage]) }
          &.[]($traits[:damage])
      healing_trait =
        potion_info
          .traits
          .find { |h| h.key?($traits[:healing]) }
          &.[]($traits[:healing])

      if damage_trait
        @enemy.combat_stats.hurt(damage_trait)
        status_label(
          (GTK.args.grid.w / 2),
          (GTK.args.grid.h - 250),
          "#{damage_trait}",
          255,
          165,
          0,
          100
        )
        end_combat if @enemy.combat_stats.dead
      elsif healing_trait
        @player.combat_stats.heal(healing_trait)
        status_label(
          80,
          (GTK.args.grid.h - 275),
          "#{healing_trait}",
          0,
          255,
          0,
          100
        )
      end
      begin_turn_stage @turn_stages[:cleanup] if not actions_available?
    end
  end

  def end_combat()
    @victory_banner_timer = Kernel.tick_count
  end

  def get_card_rects
    card_rects = []

    # Include all active hand cards
    @hand.each { |id, card| card_rects << card.rect }

    card_rects
  end

  def get_deck_rect
    { x: 20, y: 20, w: 160, h: 160 }
  end

  def get_pass_button_rect
    { x: 20, y: GTK.args.grid.h - 50 - (60 / 2), w: 160, h: 60 }
  end

  def begin_combat
    @turn_num = 0
    3.times { draw_card }

    begin_turn_stage @turn_stages[:drawing_cards]
    begin_turn_stage @turn_stages[:playing_cards]
  end
end
