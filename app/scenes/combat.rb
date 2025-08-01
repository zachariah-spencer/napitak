class Combat < Scene
  attr :sc_id, :hand_manager

  def initialize(enemy = nil)
    @sc_id = "combat"

    $files.save_data["current_enemy"] = enemy if enemy

    @turn_stages = {
      drawing_cards: 0,
      playing_hand: 1,
      cleanup: 2,
      enemy_turn: 3
    }
    @player = $player
    puts "#{@player.maximum_hp} HELP #{@player.maximum_focus}"
    @player.combat_stats.reset!(@player.maximum_hp, @player.maximum_focus)
    @enemy = Object.const_get($files.save_data["current_enemy"].capitalize).new
    @hand_manager = CardHandManager.new(player: @player, enemy: @enemy)
    @enemy_ai = EnemyAI.new(@enemy, on_turn_end: method(:calc_enemy_turn_ended))
    @tutorial_service =
      TutorialService.new(
        files: $files,
        encounter_manager: $encounter_manager,
        enemy: @enemy
      )
    @banner_alpha = 0
    @defeat_banner_timer = nil
    @victory_banner_timer = nil
    @flee_banner_timer = nil
    @fled = false
    @flee_btn_alpha = 0
    @pass_btn_alpha = 0
    @flee_attempts = 0
    @pre_deal_tick = Kernel.tick_count
    @pre_deal_time = 1.seconds
    @dealing_tick = nil
    @dealing_time = 1.seconds
    GTK.args.audio[:shuffle] = {
      input: "sounds/sfx/card/SFX_Shuffle2.wav",
      gain: 0.7
    }
    puts @hand_manager.hand
  end

  def ready
    @tutorial_service.handle_combat_start
  end

  def tick
    begin_combat if ready_for_combat?
    calc

    if dealing?
      handle_card_dealing
    else
      @enemy_ai.tick
      @player.tick
      handle_combat_end
    end
  end

  def ready_for_combat?
    @pre_deal_tick && @pre_deal_tick.elapsed_time >= @pre_deal_time
  end

  def dealing?
    @dealing_tick && @dealing_tick.elapsed_time < @dealing_time
  end

  def handle_card_dealing
    return unless @dealing_tick.elapsed_time % (@dealing_time / 4) == 0
    return unless @player.potions.all_cards.size.positive?

    @hand_manager.draw_card
  end

  def handle_combat_end
    if @enemy.combat_stats.dead && @victory_banner_timer &&
         @victory_banner_timer.elapsed_time >= 3.seconds
      leave(:victory)
    elsif @player.combat_stats.dead && @defeat_banner_timer &&
          @defeat_banner_timer.elapsed_time >= 3.seconds
      leave(:defeat)
    elsif @fled && @flee_banner_timer &&
          @flee_banner_timer.elapsed_time >= 3.seconds
      leave(:flee)
    end
  end

  def calc_enemy_turn_ended
    if @player.combat_stats.dead
      @defeat_banner_timer = Kernel.tick_count
    elsif !combat_ended? && !@enemy.combat_stats.dead &&
          !@player.combat_stats.dead
      begin_turn_stage @turn_stages[:drawing_cards]
    end
  end

  def combat_ended?
    @victory_banner_timer || @defeat_banner_timer || @flee_banner_timer
  end

  def leave(state = :victory)
    @victory_banner_timer = nil
    @defeat_banner_timer = nil
    @flee_banner_timer = nil

    case state
    when :victory
      @player.feathers += @enemy.value
      puts "FEATHERS: #{@player.feathers}"
      @player.save_feathers_data
      $encounter_manager.inc_combats_won
      if @enemy.is_boss
        $game.change_scene(
          prev_sc: @sc_id,
          next_scene: "boss_rewards_screen",
          args: [@enemy.enemy_id]
        )
      else
        $game.change_scene(prev_sc: @sc_id, next_scene: "rewards_screen")
      end
    when :defeat
      $game.end_run
    when :flee
      $game.change_scene(prev_sc: @sc_id, next_scene: "map")
    end
  end

  def calc
    @hand_manager.calc_card_positions

    if $game.input_locked
      clear_dragging_state
    elsif @player.my_turn? && !@fled
      calc_mouse_inputs
    end

    check_enemy_death
    @hand_manager.remove_marked
    fade_banners
  end

  def clear_dragging_state
    @hand_manager.hand.each { |_id, c| c.grabbed = false }
    state.currently_dragging_card_id = nil
    state.mouse_point_inside_square = nil
  end

  def check_enemy_death
    unless @enemy.combat_stats.dead && @enemy.turn_over? &&
             !@victory_banner_timer
      return
    end

    puts "ENEMY_DIED_COMBAT_ENDED\n\n"
    end_combat
  end

  def fade_banners
    if @defeat_banner_timer || @victory_banner_timer || @flee_banner_timer
      @banner_alpha = @banner_alpha.lerp(255, 0.04)
    end
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    cards = []
    tool_tips = []
    front_card = []

    @hand_manager.hand.each do |id, c|
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
    x = (Kernel.tick_count * 2) % (2 * range)
    osc_val = range - (x - range).abs

    # bg_tile_index = 0.frame_index(5, 1.0.seconds, true)
    bg_tile_index = 0.frame_index(3, 1.0.seconds, true)
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
      rect = Layout.rect(row: -1, col: 1, w: 22, h: 14)
      background = {
        x: rect[:x],
        y: rect[:y],
        w: rect[:w],
        h: rect[:h],
        a: 180,
        path:
          "sprites/background_frames/dungeon/dungeon_bg#{bg_tile_index + 1}.png"
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
      hp_label_rect = Layout.rect(col: 0.4, row: 7, w: 1, h: 1)
      hp_label_num_rect = Layout.rect(col: 0.4, row: 7.4, w: 1, h: 1)

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

      focus_label_rect = Layout.rect(col: 0.4, row: 6, w: 1, h: 1)
      focus_label_num_rect = Layout.rect(col: 0.4, row: 6.4, w: 1, h: 1)

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
        x: flee_btn[:x] + 38,
        y: flee_btn[:y] + 52,
        anchor_x: 0.5,
        size_px: 14,
        r: 255,
        g: 255,
        b: 255,
        a: @flee_btn_alpha,
        text: "#{flee_success_rate?.to_i}% CHANCE",
        font: "fonts/eaglelake.ttf",
        primitive_marker: :label
      }

      l1 << flee_percentage_label

      # if @player.combat_stats.statuses[$STATUS_TYPES[:WARD]] > 0
      #   l1 << player_ward_label
      # end
      return l1
    when 2
      deck_frame = 0.frame_index(3, 0.18.seconds, true)

      deck_rect = Layout.rect(col: 0.12, row: 10.75, w: 1.5, h: 1.5)
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

      if @player.combat_stats.focus == @player.combat_stats.mod_max_focus
        pass_btn_text = "PASS"
        rgb = [0, 255, 255]
      else
        pass_btn_text = "PASS"
        rgb = [255, 255, 255]
      end
      pass_btn_rect = Layout.rect(col: 0.2, row: 0, w: 1.5, h: 0.75)
      pass_btn_f_i = 0.frame_index(4, 0.5.seconds, true)
      pass_button =
        pass_btn_rect.merge(
          r: rgb[0],
          g: rgb[1],
          b: rgb[2],
          a: @pass_btn_alpha,
          tile_x: 96 * pass_btn_f_i,
          tile_y: 0,
          tile_w: 96,
          tile_h: 48,
          path: "sprites/wide_button_frame-sheet-6.png",
          primitive_marker: :sprite
        )

      pass_button_label =
        pass_btn_rect.center.merge(
          text: "#{pass_btn_text}",
          font: "fonts/eaglelake.ttf",
          size_px: 20,
          alignment_enum: 1,
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 255,
          g: 255,
          b: 255,
          a: @pass_btn_alpha,
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

      # l4 << @enemy.combat_stats.prefab
      l4 << @player.combat_stats.prefab
      l4 << players_turn_label if @player.my_turn?
      l4 << tool_tips
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def flee_btn
    flee_btn_frames = 0.frame_index(4, 0.5.seconds, true)
    flee_btn_rect =
      Layout.rect(
        col: Layout.col_count - 1.685,
        row: Layout.row_count - 0.325,
        w: 1.5,
        h: 0.75
      )

    GTK.args.outputs[:flee_btn].w = 96
    GTK.args.outputs[:flee_btn].h = 48
    btn_color = { r: 150, g: 150, b: 150 }
    if @player.my_turn?
      @flee_btn_alpha = @flee_btn_alpha.lerp(255, 0.1)
      @pass_btn_alpha = @pass_btn_alpha.lerp(255, 0.1)
    else
      @flee_btn_alpha = @flee_btn_alpha.lerp(0, 0.1)
      @pass_btn_alpha = @pass_btn_alpha.lerp(0, 0.1)
    end

    GTK.args.outputs[:flee_btn].primitives << flee_btn_rect.merge(
      x: 0,
      y: 0,
      angle: 0,
      path: "sprites/wide_button_frame-sheet-6.png",
      tile_x: 96 * flee_btn_frames,
      tile_y: 0,
      tile_w: 96,
      tile_h: 48,
      r: 255,
      g: 0,
      b: 0,
      primitive_marker: :sprite
    )

    GTK.args.outputs[:flee_btn].primitives << {
      x: flee_btn_rect[:w] / 2,
      y: flee_btn_rect[:h] / 2,
      text: "FLEE",
      font: "fonts/eaglelake.ttf",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_px: 22
    }

    flee_btn_rect.merge(
      w: 96,
      h: 48,
      path: :flee_btn,
      primitive_marker: :sprite,
      a: @flee_btn_alpha
    )
  end

  def cleanup
    puts "cleanup combat.rb"
    super
    state.currently_dragging_card_id = nil
    state.mouse_point_inside_square = nil
    @hand_manager.cleanup
    $event_bus.unsubscribe_owner(@enemy)

    potions_save_data = []
    @player.potions.all_cards.each { |c| potions_save_data << c.save_data? }

    $files.save_data["player"]["potions"] = potions_save_data
    $announcement_manager.clear_announcements_queue
  end

  def calc_status_effects(type:)
    @player.combat_stats.calc_status(type: type)
    @enemy.combat_stats.calc_status(type: type)
  end

  def flee_success_rate?
    enemy_hp_percentage = @enemy.combat_stats.hp / @enemy.combat_stats.max_hp
    (((1.0 - enemy_hp_percentage) * 100) + (5 * @flee_attempts)).round
  end

  def attempt_flee
    @flee_attempts += 1
    roll = Numeric.rand(0..100)
    if roll <= flee_success_rate?
      flee
    else
      GameUtils.status_label(1100, 50, "FLEE ATTEMPT FAILED", 255, 255, 255, 25)
    end

    begin_turn_stage @turn_stages[:cleanup] if !@fled
  end

  def flee
    puts "FLED"
    @player.my_turn = false
    @flee_banner_timer = Kernel.tick_count
    @fled = true
  end

  def calc_mouse_inputs
    return if $animation_manager&.input_locked? || $game.input_locked

    if GTK.args.inputs.mouse.click &&
         Geometry.intersect_rect?(inputs.mouse, flee_btn) && @player.my_turn
      puts "clicked on flee_btn"
      attempt_flee
    end

    if state.currently_dragging_card_id
      c_ref = @hand_manager.hand[state.currently_dragging_card_id]
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
          @hand_manager.draw_card
        end
        begin_turn_stage @turn_stages[:cleanup]
      end
    end

    if @turn_stage == @turn_stages[:playing_cards]
      if inputs.mouse.click and c_u_m
        state.currently_dragging_card_id = c_u_m.id
        c_ref = @hand_manager.hand[state.currently_dragging_card_id]
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
        c_ref = @hand_manager.hand[state.currently_dragging_card_id]

        if state.click_hold_time.elapsed_time < 20 &&
             (Geometry.distance c_ref.pos, c_ref.f_pos) < 20
          @hand_manager.use_card c_ref
          end_combat if @enemy.combat_stats.dead
          unless @hand_manager.actions_available?
            begin_turn_stage(@turn_stages[:cleanup])
          end
        end

        # For active hand cards, perform reordering.
        if @hand_manager.hand.key?(state.currently_dragging_card_id)
          # Exclude the dragged card from the current order.
          other_cards =
            @hand_manager.hand.values.reject do |card|
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
              card = @hand_manager.hand[card_id]
              dragged_center < (card.pos.x + (card.w / 2))
            end
          new_index ||= sorted_ids.length
          sorted_ids.insert(new_index, state.currently_dragging_card_id)

          # Rebuild the active hand from these sorted IDs.
          @hand_manager.instance_variable_set(
            :@hand,
            sorted_ids.map { |id| [id, @hand_manager.hand[id]] }.to_h
          )
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
      calc_status_effects(type: :BLIGHT)
      @hand_manager.draw_card
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

  def end_combat()
    @victory_banner_timer = Kernel.tick_count
    @player.my_turn = false
  end

  def get_card_rects
    @hand_manager.get_card_rects
  end

  def get_deck_rect
    { x: 20, y: 20, w: 160, h: 160 }
  end

  def get_pass_button_rect
    Layout.rect(col: 0.25, row: 0, w: 1.5, h: 0.75)
  end

  def begin_combat
    @dealing_tick = Kernel.tick_count
    @pre_deal_tick = nil
    @player.begin_turn
    # 3.times { @hand_manager.draw_card if @player.potions.all_cards.size > 0 }
    begin_turn_stage @turn_stages[:playing_cards]
  end
end
