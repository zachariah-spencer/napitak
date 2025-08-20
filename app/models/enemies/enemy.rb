class Enemy
  include RunOnce
  attr_gtk
  attr :hp,
       :max_hp,
       :turn_start_timer,
       :attacked,
       :attacks,
       :attacked,
       :my_turn,
       :turn_ended_signal,
       :combat_stats,
       :sprite,
       :name,
       :enemy_id,
       :is_boss,
       :value,
       :accuracy

  def initialize()
    $enemy = self
    # @enemy_id must be implemented on every enemy
    @shout_component = ShoutComponent.new(enemy_id: @enemy_id)
    @turn_start_timer = 0
    @attacked = false
    @combat_stats = nil
    @my_turn = false
    @turn_ended_signal = false
    @sprite = nil
    @name = nil
    @is_boss = false
    @accuracy = 90.0
    @value = 1
    @floating_seed = Numeric.rand(0.0..100.0)
    @damage_flash_tick = nil

    @ang = 0
    @fx = GTK.args.grid.w / 2 - 100
    @fy = GTK.args.grid.h - 250
    @x = @fx
    @y = @fy
    @w = 200
    @h = 200
    @fang = 0

    @attack_y = GTK.args.grid.h - 250 - 500
    @home_y = GTK.args.grid.h - 250

    @attacks = {}

    $EVENT_BUS.subscribe(:enemy_hurt, self) do |data|
      hurt(data[:amount], data[:type])
    end
    $EVENT_BUS.subscribe(:enemy_heal, self) { |amt| @combat_stats.heal(amt) }
    $EVENT_BUS.subscribe(:enemy_apply_status, self) do |data|
      @combat_stats.apply_status(type: data[:type], stacks: data[:stacks])
    end
  end

  def attack
    attack = select_attack
    $animation_manager.queue_animation(attack[:attack_id], lock_input: true)
    hit_roll = Numeric.rand(0.0..100.0)
    if hit_roll <= modified_accuracy?
      handle_attack_effects(attack)
    else
      GameUtils.status_label(
        GTK.args.grid.w / 2,
        GTK.args.grid.h - 250,
        "MISSED",
        255,
        255,
        255,
        64
      )
    end
    @attacked = true
  end

  def modified_accuracy?
    puts "ACCURACY: #{@accuracy}\n ACCURACY_MODIFIER: #{@combat_stats.accuracy_mod}\nFINAL_CALC: #{@accuracy + @combat_stats.accuracy_mod}\n"
    @accuracy + @combat_stats.accuracy_mod
  end

  def hurt(amt, type)
    @shout_component.shout_defensively
    $AUDIO_SERVICE.play_sound("#{@enemy_id}_hurt".to_sym, rand_pitch: true)
    @combat_stats.hurt(amt, type)
  end

  def handle_attack_effects(attack)
    # handle potion card behavior
    damage_trait =
      attack
        .traits
        .find { |h| h.key?($CARD_TRAITS[:damage]) }
        &.[]($CARD_TRAITS[:damage])
    mend_trait =
      attack
        .traits
        .find { |h| h.key?($CARD_TRAITS[:mend]) }
        &.[]($CARD_TRAITS[:mend])
    restoration_trait =
      attack
        .traits
        .find { |h| h.key?($CARD_TRAITS[:restoration]) }
        &.[]($CARD_TRAITS[:restoration])
    scorch_trait =
      attack
        .traits
        .find { |h| h.key?($CARD_TRAITS[:scorch]) }
        &.[]($CARD_TRAITS[:scorch])
    blight_trait =
      attack
        .traits
        .find { |h| h.key?($CARD_TRAITS[:blight]) }
        &.[]($CARD_TRAITS[:blight])

    frost_trait =
      attack
        .traits
        .find { |h| h.key?($CARD_TRAITS[:frost]) }
        &.[]($CARD_TRAITS[:frost])

    ward_trait =
      attack
        .traits
        .find { |h| h.key?($CARD_TRAITS[:ward]) }
        &.[]($CARD_TRAITS[:ward])

    blind_trait = attack.traits.find { |h| h.key?($CARD_TRAITS[:blind]) }
    blind_trait &&= blind_trait[$CARD_TRAITS[:blind]]

    if damage_trait
      $EVENT_BUS.publish(
        :player_hurt,
        amount: damage_trait[:amount],
        type: damage_trait[:type]
      )
    end

    $EVENT_BUS.publish(:enemy_heal, mend_trait) if mend_trait

    if restoration_trait
      $EVENT_BUS.publish(
        :enemy_apply_status,
        type: :RESTORATION,
        stacks: restoration_trait
      )
    end

    if scorch_trait
      $EVENT_BUS.publish(
        :player_apply_status,
        type: :SCORCH,
        stacks: scorch_trait
      )
    end

    if blight_trait
      $EVENT_BUS.publish(
        :player_apply_status,
        type: :BLIGHT,
        stacks: blight_trait
      )
    end

    if frost_trait
      $EVENT_BUS.publish(
        :player_apply_status,
        type: :FROST,
        stacks: frost_trait
      )
    end

    if ward_trait
      $EVENT_BUS.publish(:enemy_apply_status, type: :WARD, stacks: ward_trait)
    end

    if blind_trait
      $EVENT_BUS.publish(
        :player_apply_status,
        type: :BLIND,
        stacks: blind_trait
      )
    end
  end

  def select_attack
    # Build an array of [weight, attack_data] while preserving insertion order.
    weighted_attacks = @attacks.map { |weight, atk| [weight, atk] }
    return weighted_attacks.first.last if weighted_attacks.empty?

    total_weight = weighted_attacks.sum { |w, _| w }
    # Avoid division by zero or invalid ranges when total_weight is 0.
    return weighted_attacks.first.last if total_weight <= 0

    rand_n = Numeric.rand(0...total_weight)
    cumulative = 0

    weighted_attacks.each do |weight, attack|
      cumulative += weight
      return attack if rand_n < cumulative
    end

    weighted_attacks.last.last
  end

  def begin_turn
    @combat_stats.calc_status(type: :RESTORATION)
    frost_stacks = @combat_stats.statuses[$STATUS_TYPES[:FROST]]
    if frost_stacks > 0
      @combat_stats.calc_status(type: :FROST)
      end_turn
    else
      @shout_component.shout_offensively
      @my_turn = true
      @turn_start_timer = Kernel.tick_count
    end
  end

  def tick
    @combat_stats.tick
    if @my_turn and not @combat_stats.dead
      calc
    elsif @combat_stats.dead
      @combat_stats.calc_status(type: :FROST)
      end_turn
    end

    if !@combat_stats.dead
      @shout_component.tick
      calc_float
    else
      run_once(:publish_death) { $EVENT_BUS.publish(:enemy_died) }
      calc_death_anim
    end
  end

  def calc_death_anim
    @w = @w.lerp(0, 0.025)
    @h = @h.lerp(0, 0.025)
    dx = @x + 50
    dy = @y + 50
    @x = @x.lerp(dx, 0.01)
    @y = @y.lerp(dy, 0.01)
    @ang += 10
  end

  def calc
    if not @attacked
      attack if @turn_start_timer.elapsed_time >= 1.seconds
    end

    calc_end_turn
  end

  def calc_float
    if @my_turn and @turn_start_timer.elapsed_time < 0.85.seconds
      # if @turn_start_timer.elapsed_time > 1.seconds or @turn_start_timer = 0
      @fx = @fx + (Math.cos(@floating_seed + Kernel.tick_count * 0.85) * 5)
    elsif @my_turn and @turn_start_timer.elapsed_time >= 0.85.seconds and
          @turn_start_timer.elapsed_time < 1.0.seconds
      @fy = @attack_y
    elsif @my_turn and @turn_start_timer.elapsed_time >= 1.0.seconds
      @fx = GTK.args.grid.w / 2 - 100
      @fy = @home_y
    else
      @fx = @fx + (Math.cos(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
      @fy = @fy + (Math.sin(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
    end
    @fang = Math.sin(@floating_seed + Kernel.tick_count * 0.005) * 2

    @x = @x.lerp @fx, 0.2
    @y = @y.lerp @fy, 0.2
    @ang = @ang.lerp @fang, 0.2
  end

  def turn_over?
    val = @turn_ended_signal
    @turn_ended_signal = false
    val
  end

  def calc_end_turn
    # check end turn
    end_turn if attack_completed?
  end

  def end_turn
    @attacked = false
    @my_turn = false
    @turn_ended_signal = true
    @combat_stats.calc_status(type: :SCORCH)
    $player.combat_stats.calc_status(type: :SCORCH)
  end

  def attack_completed?
    attacked and not $animation_manager&.input_locked? and @my_turn
  end

  def prefab

    sprite_frame =
        0.frame_index(
          count: 3,
          hold_for: 30,
          repeat: true,
          repeat_index: 0,
          tick_count_override: Kernel.tick_count
        )
    enemy_sprite ||= {
      x: @x,
      y: @y,
      angle: @ang,
      w: @w,
      h: @h,
      r: @r,
      path: @sprite,
      tile_x: (sprite_frame * 128),
      tile_y: 0,
      tile_w: 128,
      tile_h: 128,
      primitive_marker: :sprite
    }
    enemy_sprite ||= {
      x: @x,
      y: @y,
      angle: @ang,
      w: @w,
      h: @h,
      r: @r,
      path: @sprite,
      primitive_marker: :sprite
    }

    enemy_hp_label ||= {
      x: GTK.args.grid.w / 2,
      y: GTK.args.grid.h - 270,
      alignment_enum: 1,
      size_px: 20,
      r: 150,
      g: 0,
      b: 0,
      text: "#{@combat_stats.hp} / #{@combat_stats.max_hp}",
      font: $FONT,
      primitive_marker: :label
    }

    if !@combat_stats.dead && @shout_component.prefab
      enemy_shout = @shout_component.prefab
    else
      enemy_shout = nil
    end

    array = [enemy_sprite, enemy_hp_label, @combat_stats.prefab]
    array << enemy_shout if enemy_shout
    array
  end
end
