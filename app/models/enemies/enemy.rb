class Enemy
  attr_gtk
  attr :hp, :max_hp, :turn_start_timer, :attacked, :attacks, :attacked, :my_turn, :turn_ended_signal, :combat_stats, :sprite, :name

  def initialize()
    $enemy = self
    @turn_start_timer = 0
    @attacked = false
    @combat_stats = nil
    @my_turn = false
    @turn_ended_signal = false
    @sprite = nil
    @name = nil

    @floating_seed = Numeric.rand(0.0..100.0)

    
    @ang = 0
    @fx = GTK.args.grid.w / 2 - 100
    @fy = GTK.args.grid.h - 250
    @x = @fx
    @y = @fy
    @fang = 0
    
    
    @attacks = {}
  end

  def attack
    attack = select_attack
    $animation_manager.queue_animation(attack[:attack_id], lock_input: true)
    handle_attack_effects(attack)
    # $player.combat_stats.hurt(attack[:damage])
    @attacked = true
  end

  def handle_attack_effects(attack)
    # handle potion card behavior
    damage_trait =
      attack
        .traits
        .find { |h| h.key?($traits[:damage]) }
        &.[]($traits[:damage])
    mend_trait =
      attack
        .traits
        .find { |h| h.key?($traits[:mend]) }
        &.[]($traits[:mend])
    restoration_trait =
      attack
        .traits
        .find { |h| h.key?($traits[:restoration]) }
        &.[]($traits[:restoration])
    scorch_trait =
      attack
        .traits
        .find { |h| h.key?($traits[:scorch]) }
        &.[]($traits[:scorch])
    blight_trait =
      attack
        .traits
        .find { |h| h.key?($traits[:blight]) }
        &.[]($traits[:blight])
    
    frost_trait =
      attack
        .traits
        .find { |h| h.key?($traits[:frost]) }
        &.[]($traits[:frost])
    
    ward_trait =
      attack
        .traits
        .find { |h| h.key?($traits[:ward]) }
        &.[]($traits[:ward])

    if damage_trait
      $player.combat_stats.hurt(damage_trait[:amount], damage_trait[:type])
    end
    
    if mend_trait
      @combat_stats.heal(mend_trait)
    end

    if restoration_trait
      @combat_stats.apply_status(type: "RESTORATION", stacks: restoration_trait)
    end

    if scorch_trait
      $player.combat_stats.apply_status(type: "SCORCH", stacks: scorch_trait)
    end

    if blight_trait
      $player.combat_stats.apply_status(type: "BLIGHT", stacks: blight_trait)
    end

    if frost_trait
      $player.combat_stats.apply_status(type: "FROST", stacks: frost_trait)
    end

    if ward_trait
      @combat_stats.apply_status(type: "WARD", stacks: ward_trait)
    end
  end

  def select_attack
    rand_n = Numeric.rand(0..100)
    att_probs = @attacks.keys
    attack = 0

    if rand_n >= 0 and rand_n < att_probs[0]
      attack = @attacks[att_probs[0]]
    elsif rand_n >= att_probs[0] and rand_n < (att_probs[0] + att_probs[1])
      attack = @attacks[att_probs[1]]
    elsif rand_n >= (att_probs[0] + att_probs[1]) and
          rand_n < (att_probs[0] + att_probs[1] + att_probs[2])
      attack = @attacks[att_probs[2]]
    end

    attack
  end


  def begin_turn
    @combat_stats.calc_status(type:"RESTORATION")
    frost_stacks = @combat_stats.statuses[$STATUS_TYPES["FROST"]]
    if frost_stacks > 0
      @combat_stats.calc_status(type:"FROST")
      end_turn
    else
      @my_turn = true
      @turn_start_timer = Kernel.tick_count
    end
  end

  def tick
    @combat_stats.tick
    if @my_turn and not @combat_stats.dead
      calc
    elsif @combat_stats.dead
      @combat_stats.calc_status(type:"FROST")
      end_turn
    end

    calc_float
  end

  def calc
    if not @attacked
      attack if @turn_start_timer.elapsed_time == 1.seconds
    end

    calc_end_turn
  end

  def calc_float
    if @my_turn and @turn_start_timer.elapsed_time < 0.85.seconds
    # if @turn_start_timer.elapsed_time > 1.seconds or @turn_start_timer = 0
      @fx = @fx + (Math.cos(@floating_seed + Kernel.tick_count * 0.85) * 5)
    elsif @my_turn and @turn_start_timer.elapsed_time == 0.85.seconds
      @fy = @fy - 500
    elsif @my_turn and @turn_start_timer.elapsed_time == 1.0.seconds
      @fx = GTK.args.grid.w / 2 - 100
      @fy = GTK.args.grid.h - 250
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
    if attack_completed?
      end_turn
    end
  end

  def end_turn
    @attacked = false
    @my_turn = false
    @turn_ended_signal = true
    @combat_stats.calc_status(type:"SCORCH")
    $player.combat_stats.calc_status(type:"SCORCH")
  end

  def attack_completed?
    attacked and not $animation_manager&.input_locked? and @my_turn
  end

  def prefab
    if not @combat_stats.dead
      enemy_sprite ||= {
        x: @x,
        y: @y,
        angle: @ang,
        w: 200,
        h: 200,
        path: @sprite,
        primitive_marker: :sprite
      }

      enemy_hp_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 270,
        alignment_enum: 1,
        size_enum: 5,
        r: 150,
        g: 0,
        b: 0,
        text: "#{@combat_stats.hp}/#{@combat_stats.max_hp}",
        primitive_marker: :label
      }

      [enemy_sprite, enemy_hp_label]
    end
  end
end
