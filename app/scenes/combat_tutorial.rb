class CombatTutorial < Scene
  include CombatStatusEffects
  attr :sc_id

  def initialize()
    @sc_id = "combat_tutorial"

    @turn_stages = {
      drawing_cards: 0,
      playing_hand: 1,
      cleanup: 2,
      enemy_turn: 3
    }
    @hand = {}
    @matching_potion = nil
    @max_hand_size = 5
    @turn_stage = nil
    @turn_num = -1
    @player = $player
    @player.combat_stats.reset!(100, 4)
    @enemy = AbyssalTutorial.new
    @banner_alpha = 0
    @defeat_banner_timer = nil
    @victory_banner_timer = nil
    @flee_banner_timer = nil
    @fled = false
    @attempting_flee = false
    @flee_attempts = 0
    @card_hovered_tutorial_played = false
    @second_card_hovered_tutorial_played = false
    setup_tutorial_deck
    begin_combat
  end

  def ready
    $TUTORIAL_INDEX = 0
    id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)

    GameUtils.announce(
      text: text,
      duration: 5.5.seconds,
      tutorial_id: id,
      x: GTK.args.grid.w / 2 - 200,
      y: 250
    )

    $TUTORIAL_INDEX = 1
    id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)

    GameUtils.announce(
      text: text,
      duration: 4.5.seconds,
      tutorial_id: id,
      x: 175,
      y: 275
    )

    $TUTORIAL_INDEX = 2
    id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)

    GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
  end

  def tick
    calc
    @enemy.tick
    @player.tick
    if @enemy.combat_stats.dead && @victory_banner_timer &&
         @victory_banner_timer.elapsed_time >= 3.seconds
      leave(0)
    end
    # if @player.combat_stats.dead && @defeat_banner_timer &&
    #      @defeat_banner_timer.elapsed_time >= 3.seconds
    #   leave(1)
    # end
    if @fled && @flee_banner_timer &&
         @flee_banner_timer.elapsed_time >= 3.seconds
      leave(2)
    end

    handle_hover_tooltip_tutorial
  end

  def handle_hover_tooltip_tutorial
    if $announcement_manager.no_announcements? &&
         !@card_hovered_tutorial_played && !$game.input_locked &&
         @turn_num >= 4 && card_hovered?
      @card_hovered_tutorial_played = true

      $TUTORIAL_INDEX = 3
      id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
      GameUtils.announce(text: text, duration: 5.0.seconds, tutorial_id: id)
      $TUTORIAL_INDEX = 4
      id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
      GameUtils.announce(
        text: text,
        duration: 5.0.seconds,
        tutorial_id: id,
        x: $TUTORIAL_HOVERED_CARD.pos[:x] - 220,
        y: $TUTORIAL_HOVERED_CARD.pos[:y] - 25
      )
      $TUTORIAL_INDEX = 5
      id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
      GameUtils.announce(
        text: text,
        duration: 6.0.seconds,
        tutorial_id: id,
        x: $TUTORIAL_HOVERED_CARD.pos[:x] - 120,
        y: $TUTORIAL_HOVERED_CARD.pos[:y] - 25
      )
      $TUTORIAL_INDEX = 6
      id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
      GameUtils.announce(
        text: text,
        duration: 6.0.seconds,
        tutorial_id: id,
        x: $TUTORIAL_HOVERED_CARD.pos[:x] + 0,
        y: $TUTORIAL_HOVERED_CARD.pos[:y] - 25
      )
    end

    if $announcement_manager.no_announcements? &&
         !@second_card_hovered_tutorial_played && card_hovered? &&
         !$game.input_locked && @turn_num >= 3
      @second_card_hovered_tutorial_played = true
      #MORE TUT MESSAGES
    end
  end

  def calc_player_revive
    if @player.combat_stats.dead &&
         @player.combat_stats.dead_tick.elapsed_time >= 0.5.seconds
      @player.combat_stats.hp = @player.combat_stats.max_hp
      @player.combat_stats.dead = false
      @player.combat_stats.dead_tick = nil
      GameUtils.announce_lg(
        text:
          "You are reinvigorated with a determination to protect your laboratory.",
        duration: 2.0.seconds
      )
      begin_turn_stage @turn_stages[:drawing_cards]
    end
  end

  def calc_enemy_turn_ended
    begin_turn_stage @turn_stages[:drawing_cards] if !@player.combat_stats.dead
  end

  def leave(state = 0)
    @victory_banner_timer = nil
    @defeat_banner_timer = nil
    @flee_banner_timer = nil
    state_enum = { victory: 0, defeat: 1, flee: 2 }
    $game.change_scene(
      prev_sc: @sc_id,
      next_scene: "alchemy_lab",
      args: [{ tutorial: true }]
    )
  end

  def calc
    calc_card_positions

    if !$game.input_locked
      calc_mouse_inputs if @player.my_turn? && !@fled
    else
      @hand.each { |id, c| c.grabbed = false }
      state.currently_dragging_card_id = nil
      state.mouse_point_inside_square = nil
    end

    if !@enemy.combat_stats.dead
      if @enemy.turn_over?
        puts "ENEMY_TURN_ENDED\n\n"
        calc_enemy_turn_ended
      end
    else
      if @enemy.turn_over? and not @victory_banner_timer
        puts "ENEMY_DIED_COMBAT_ENDED\n\n"
        end_combat
      end
    end

    calc_player_revive if @player.combat_stats.dead && !@enemy.my_turn
    calc_attempt_flee_end

    calc_entity_removals
    @banner_alpha = @banner_alpha.lerp(255, 0.04) if @defeat_banner_timer or
      @victory_banner_timer or @flee_banner_timer
  end

  def card_hovered?
    hovered = false
    hovered_card =
      @hand.each do |id, c|
        if c.hovered
          hovered = true
          $TUTORIAL_HOVERED_CARD = c
        end
      end
    hovered
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    cards ||= []
    tool_tips ||= []
    front_card = []

    @hand.each do |id, c|
      tool_tip = nil
      card = nil
      if c.grabbed
        front_card << c.prefab
      else
        card, tool_tip = c.prefab
        cards << card
        tool_tips << tool_tip
      end
    end

    range = 255 - 0
    x = (Kernel.tick_count * 5) % (2 * range)
    osc_val = range - (x - range).abs

    bg_tile_index = 0.frame_index(5, 1.0.seconds, true)
    tile_index = 0.frame_index(6, 0.25.seconds, true)

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
      rect = Layout.rect(row: 0, col: 1, w: 22, h: 14)
      background = {
        x: rect[:x],
        y: rect[:y],
        w: rect[:w],
        h: rect[:h],
        path: "sprites/background_frames/woods/woods_bg#{bg_tile_index + 1}.png" # "sprites/background_frames/woods/woods_bg#{bg_tile_index + 1}.png"
      }

      l0 << [background_solid, background]
      return l0
    when 1
      left_panel ||= {
        x: 0,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        path: "sprites/panel_blue.png",
        primitive_marker: :sprite
      }

      right_panel ||= {
        x: GTK.args.grid.w - 200,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        path: "sprites/panel_blue.png",
        primitive_marker: :sprite
      }

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

      hp_label_rect = Layout.rect(col: 0.4, row: 0.5, w: 1, h: 1)
      hp_label_num_rect = Layout.rect(col: 0.4, row: 0.9, w: 1, h: 1)

      player_hp_label_header =
        hp_label_rect.center.merge(
          anchor_x: 0.5,
          size_px: 20,
          r: 255,
          g: 255,
          b: 255,
          text: "HP",
          font: "fonts/eaglelake.ttf",
          primitive_marker: :label
        )

      player_hp_label =
        hp_label_num_rect.center.merge(
          anchor_x: 0.5,
          size_px: 20,
          r: 0,
          g: 150,
          b: 0,
          text: "#{@player.combat_stats.hp} / #{@player.combat_stats.max_hp}",
          font: "fonts/eaglelake.ttf",
          primitive_marker: :label
        )

      player_ward_label ||= {
        x: 100,
        y: GTK.args.grid.h - 315,
        alignment_enum: 1,
        size_px: 20,
        r: 255,
        g: 255,
        b: 0,
        text: "#{@player.combat_stats.statuses[$STATUS_TYPES[:WARD]]}",
        font: "fonts/eaglelake.ttf",
        primitive_marker: :label
      }

      focus_label_rect = Layout.rect(col: 0.4, row: 1.5, w: 1, h: 1)
      focus_label_num_rect = Layout.rect(col: 0.4, row: 1.9, w: 1, h: 1)

      player_focus_label_header =
        focus_label_rect.center.merge(
          size_px: 20,
          anchor_x: 0.5,
          r: 255,
          g: 255,
          b: 255,
          text: "FOCUS",
          font: "fonts/eaglelake.ttf",
          primitive_marker: :label
        )

      player_focus_label =
        focus_label_num_rect.center.merge(
          size_px: 20,
          anchor_x: 0.5,
          r: 0,
          g: 150,
          b: 150,
          text:
            "#{@player.combat_stats.focus} / #{@player.combat_stats.max_focus}",
          font: "fonts/eaglelake.ttf",
          primitive_marker: :label
        )

      l1 << [
        left_panel_a,
        right_panel_a,
        @enemy.prefab,
        player_hp_label_header,
        player_hp_label,
        player_focus_label_header,
        player_focus_label
      ]

      flee_percentage_label = {
        x: flee_btn[:x] + 40,
        y: flee_btn[:y] + 64,
        anchor_x: 0.5,
        size_px: 20,
        r: 255,
        g: 255,
        b: 255,
        a: 255,
        text: "#{flee_success_rate?.to_i}% Chance",
        font: "fonts/eaglelake.ttf",
        primitive_marker: :label
      }

      l1 << flee_percentage_label

      if @player.combat_stats.statuses[$STATUS_TYPES[:WARD]] > 0
        l1 << player_ward_label
      end
      return l1
    when 2
      deck_frame = 0.frame_index(3, 0.18.seconds, true)

      deck_rect = Layout.rect(col: 0.12, row: 10.75, w: 1.5, h: 1.5)
      puts deck_rect
      deck_sprite =
        deck_rect.merge(
          primitive_marker: :sprite,
          path: "sprites/deck_sheet.png",
          tile_x: 0 + (deck_frame * 128),
          tile_y: 0,
          tile_w: 128,
          tile_h: 128
        )

      deck_card_count_label =
        deck_rect.center.merge(
          text: "#{@player.potions.size}",
          font: "fonts/eaglelake.ttf",
          anchor_x: 0.5,
          anchor_y: 0.5,
          size_px: 20,
          r: 255,
          g: 255,
          b: 255,
          primitive_marker: :label
        )

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

      pass_btn_rect = Layout.rect(col: 0.2, row: 0, w: 1.5, h: 0.75)

      pass_button =
        pass_btn_rect.merge(r: 40, g: 40, b: 40, primitive_marker: :solid)

      if @player.combat_stats.focus == @player.combat_stats.mod_max_focus
        pass_btn_text = "PASS"
        pass_btn_size = 20
      else
        pass_btn_text = "NEXT"
        pass_btn_size = 20
      end

      pass_button_label =
        pass_btn_rect.center.merge(
          text: "#{pass_btn_text}",
          font: "fonts/eaglelake.ttf",
          size_px: pass_btn_size,
          alignment_enum: 1,
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 255,
          g: 255,
          b: 255,
          primitive_marker: :label
        )

      l2 << [
        deck_sprite,
        deck_card_count_label,
        pass_button,
        pass_button_label,
        cards,
        flee_btn
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
          size_px: 32,
          r: 255,
          g: 255,
          b: 255,
          a: @banner_alpha,
          font: "fonts/eaglelake.ttf",
          text: "DEFEAT",
          primitive_marker: :label
        }

        defeat_banner ||= {
          x: 0,
          y: GTK.args.grid.h / 2 - 50,
          w: GTK.args.grid.w,
          h: 100,
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
          size_px: 32,
          r: 255,
          g: 255,
          b: 255,
          a: @banner_alpha,
          font: "fonts/eaglelake.ttf",
          text: "VICTORY",
          primitive_marker: :label
        }

        victory_banner ||= {
          x: 0,
          y: GTK.args.grid.h / 2 - 50,
          w: GTK.args.grid.w,
          h: 100,
          r: 0,
          g: 150,
          b: 0,
          a: @banner_alpha,
          primitive_marker: :solid
        }
        l4 << [victory_banner, victory_banner_label]
      end

      if @flee_banner_timer
        flee_banner_label ||= {
          x: GTK.args.grid.w / 2,
          y: GTK.args.grid.h / 2,
          alignment_enum: 1,
          anchor_x: 0.5,
          anchor_y: 0.5,
          size_px: 32,
          r: 255,
          g: 255,
          b: 255,
          a: @banner_alpha,
          font: "fonts/eaglelake.ttf",
          text: "FLED",
          primitive_marker: :label
        }

        flee_banner ||= {
          x: 0,
          y: GTK.args.grid.h / 2 - 50,
          w: GTK.args.grid.w,
          h: 100,
          r: 0,
          g: 0,
          b: 150,
          a: @banner_alpha,
          primitive_marker: :solid
        }

        l4 << [flee_banner, flee_banner_label]
      end

      players_turn_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2,
        size_px: 26,
        r: 255,
        g: 255,
        b: 255,
        a: osc_val,
        alignment_enum: 1,
        font: "fonts/eaglelake.ttf",
        text: "YOUR TURN"
      }

      l4 << @enemy.combat_stats.prefab
      l4 << @player.combat_stats.prefab
      l4 << players_turn_label if @player.my_turn?
      l4 << tool_tips
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def flee_btn
    flee_btn_rect =
      Layout.rect(
        col: Layout.col_count - 1.75,
        row: Layout.row_count - 0.5,
        w: 1.5,
        h: 0.75
      )

    GTK.args.outputs[:flee_btn].w = flee_btn_rect[:w]
    GTK.args.outputs[:flee_btn].h = flee_btn_rect[:h]

    GTK.args.outputs[:flee_btn].primitives << flee_btn_rect.merge(
      x: 0,
      y: 0,
      angle: 0,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    )

    btn_color = { r: 150, g: 150, b: 150 }
    btn_color = { r: 80, g: 80, b: 200 } if @player.my_turn?

    GTK.args.outputs[:flee_btn].primitives << {
      x: 5,
      y: 5,
      w: flee_btn_rect[:w] - 5,
      h: flee_btn_rect[:h] - 5,
      angle: 0,
      r: btn_color[:r],
      g: btn_color[:g],
      b: btn_color[:b],
      primitive_marker: :solid
    }

    GTK.args.outputs[:flee_btn].primitives << {
      x: flee_btn_rect[:w] / 2 + 2.5,
      y: flee_btn_rect[:h] / 2 + 2.5,
      text: "FLEE",
      font: "fonts/eaglelake.ttf",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_px: 20
    }

    flee_btn_rect.merge(path: :flee_btn, primitive_marker: :sprite)
  end

  def cleanup
    puts "cleanup combat.rb"
    state.currently_dragging_card_id = nil
    state.mouse_point_inside_square = nil
    $event_bus.unsubscribe_owner(@enemy)
    @hand.each { |id, c| @player.potions.add(c) }

    potions_save_data = []
    @player.potions.all_cards.each { |c| potions_save_data << c.save_data? }

    $files.save_data["player"]["potions"] = potions_save_data
    $announcement_manager.clear_announcements_queue
  end

  def calc_card_positions
    @hand.each_with_index do |(id, c), i|
      c.calc_position(@hand.length, i)
      c.tick()
    end
  end


  def flee_success_rate?
    enemy_hp_percentage = @enemy.combat_stats.hp / @enemy.combat_stats.max_hp
    (((1.0 - enemy_hp_percentage) * 100) + (5 * @flee_attempts)).round
  end

  def attempt_flee
    GameUtils.announce_lg(
      text: "There is no escaping the darkness...",
      duration: 1.25.seconds
    )
    @attempting_flee = true
    puts $announcement_manager.announcements
    puts $announcement_manager.current_announcement
  end

  def calc_attempt_flee_end
    if @attempting_flee && !@fled && GameUtils.current_announcement_completed?
      puts "HERE"
      @attempting_flee = false
      begin_turn_stage @turn_stages[:cleanup] if !@fled
    end
  end

  def flee
    puts "FLED"
    @player.my_turn = false
    @flee_banner_timer = Kernel.tick_count
    @fled = true
  end

  def calc_entity_removals
    @hand.reject! { |id, c| c.needs_removed }
  end

  def calc_mouse_inputs
    return if $animation_manager&.input_locked? || $game.input_locked

    if GTK.args.inputs.mouse.click &&
         Geometry.intersect_rect?(inputs.mouse, flee_btn) && @player.my_turn
      puts "clicked on flee_btn"
      attempt_flee
    end

    if state.currently_dragging_card_id
      c_ref = @hand[state.currently_dragging_card_id]
    else
      #card_under_mouse lol
      c_u_m =
        Geometry.find_intersect_rect inputs.mouse, get_card_rects().reverse
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
        if @player.combat_stats.focus == @player.combat_stats.max_focus
          draw_card
        end
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

      case @turn_num
      when 2
        puts "Focus Tutorial"
        $TUTORIAL_INDEX = 7
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(
          text: text,
          duration: 5.0.seconds,
          tutorial_id: id,
          y: 500
        )
      when 3
        puts "Scorch tutorial messages!"
        $TUTORIAL_INDEX = 8
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(
          text: text,
          duration: 3.0.seconds,
          tutorial_id: id,
          y: 500
        )
        $TUTORIAL_INDEX = 9
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(
          text: text,
          duration: 3.0.seconds,
          tutorial_id: id,
          x: 200,
          y: 300
        )
        $TUTORIAL_INDEX = 10
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(
          text: text,
          duration: 3.0.seconds,
          tutorial_id: id,
          x: 200,
          y: 300
        )
      when 4
        puts "TUTS AFTER THIRD ATTACK"
      when 5
        puts "Extra card draw on pass tutorial"
        $TUTORIAL_INDEX = 11
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(
          text: text,
          duration: 6.0.seconds,
          tutorial_id: id,
          y: 500
        )
      end

      calc_status_effects(type: :BLIGHT)
      draw_card
      begin_turn_stage @turn_stages[:playing_cards]
    elsif new_stage == @turn_stages[:playing_cards]
      puts "start playing_cards stage"
    elsif new_stage == @turn_stages[:cleanup]
      puts "start cleanup stage"
      @player.my_turn = false
      calc_status_effects(type: :SCORCH)
      begin_turn_stage @turn_stages[:enemy_turn]
    elsif new_stage == @turn_stages[:enemy_turn]
      @enemy.begin_turn
    end
  end

  def setup_tutorial_deck
    # array of cards for the player to start with
    starting_pots = [
      GameUtils.gen_new_card("p001"),
      GameUtils.gen_new_card("p001"),
      GameUtils.gen_new_card("p001"),
      GameUtils.gen_new_card("p001"),
      GameUtils.gen_new_card("p001"),
      GameUtils.gen_new_card("p001"),
      GameUtils.gen_new_card("p001"),
      GameUtils.gen_new_card("p003"),
      GameUtils.gen_new_card("p003"),
      GameUtils.gen_new_card("p003"),
      GameUtils.gen_new_card("p003"),
      GameUtils.gen_new_card("p003"),
      GameUtils.gen_new_card("p003"),
      GameUtils.gen_new_card("p003")
    ]
    $player.potions = Inventory.new(starting_pots)
  end

  def draw_card
    GameUtils.status_label(700, 200, "NO CARDS IN DECK", 255, 255, 255, 40) if @player.potions.all_cards.size <= 0
    GameUtils.status_label(700, 200, "NO ROOM IN HAND", 255, 255, 255, 40) if @hand.size >= @max_hand_size
    if @player.potions.all_cards.size > 0 && @hand.size < @max_hand_size
      card = @player.potions.draw(true)
      @hand[card.entity_id] = card
    end
  end

  def actions_available?
    return true if (@player.combat_stats.focus > 0 and @hand.length >= 1)
  end

  def use_card(card)
    potion_info = $PIDS[card.id]
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
          .find { |h| h.key?($CARD_TRAITS[:damage]) }
          &.[]($CARD_TRAITS[:damage])
      mend_trait =
        potion_info
          .traits
          .find { |h| h.key?($CARD_TRAITS[:mend]) }
          &.[]($CARD_TRAITS[:mend])
      restoration_trait =
        potion_info
          .traits
          .find { |h| h.key?($CARD_TRAITS[:restoration]) }
          &.[]($CARD_TRAITS[:restoration])
      scorch_trait =
        potion_info
          .traits
          .find { |h| h.key?($CARD_TRAITS[:scorch]) }
          &.[]($CARD_TRAITS[:scorch])
      blight_trait =
        potion_info
          .traits
          .find { |h| h.key?($CARD_TRAITS[:blight]) }
          &.[]($CARD_TRAITS[:blight])

      frost_trait =
        potion_info
          .traits
          .find { |h| h.key?($CARD_TRAITS[:frost]) }
          &.[]($CARD_TRAITS[:frost])

      ward_trait =
        potion_info
          .traits
          .find { |h| h.key?($CARD_TRAITS[:ward]) }
          &.[]($CARD_TRAITS[:ward])

      if damage_trait
        $event_bus.publish(:enemy_hurt, amount: damage_trait[:amount], type: damage_trait[:type])
      end

      $event_bus.publish(:player_heal, mend_trait) if mend_trait

      if restoration_trait
        $event_bus.publish(:player_apply_status, type: :RESTORATION, stacks: restoration_trait)
      end

      if scorch_trait
        $event_bus.publish(:enemy_apply_status, type: :SCORCH, stacks: scorch_trait)
      end

      if blight_trait
        $event_bus.publish(:enemy_apply_status, type: :BLIGHT, stacks: blight_trait)
      end

      if frost_trait
        $event_bus.publish(:enemy_apply_status, type: :FROST, stacks: frost_trait)
      end

      if ward_trait
        $event_bus.publish(:player_apply_status, type: :WARD, stacks: ward_trait)
      end

      end_combat if @enemy.combat_stats.dead
      begin_turn_stage @turn_stages[:cleanup] if not actions_available?
    end
  end

  def end_combat()
    @victory_banner_timer = Kernel.tick_count
    @player.my_turn = false
    GameUtils.announce_lg(
      text: "The creature has fled and disappeared into the cover of night.",
      duration: 3.0.seconds
    )
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
