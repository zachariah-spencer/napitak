class AbyssalTutorial < Enemy
  ANIMATIONS = {
    idle: {
      path: "sprites/abyssal_idle_sheet_512x512_10.png",
      count: 10,
      hold_for: 10,
      repeat: true
    },
    hurt: {
      path: "sprites/abyssal_hurt_sheet_512x512_10.png",
      count: 10,
      hold_for: 6,
      repeat: false
    },
    death: {
      path: "sprites/abyssal_death_sheet_512x512_10.png",
      count: 10,
      hold_for: 8,
      repeat: false
    },
    attacks: {
      one: {
        path: "sprites/abyssal_attack_1_sheet_512x512_10.png",
        count: 10,
        hold_for: 5,
        impact_frame:6,
        repeat: false,
        sfx: :event_neutral
      },
      two: {
        path: "sprites/abyssal_attack_2_sheet_512x512_10.png",
        count: 10,
        hold_for: 7,
        impact_frame: 6,
        repeat: false,
        sfx: :event_neutral
      },
      three: {
        path: "sprites/abyssal_attack_3_sheet_512x512_16.png",
        count: 16,
        hold_for: 5,
        impact_frame: 6,
        repeat: false,
        sfx: :event_neutral
      },
      four: {
        path: "sprites/abyssal_attack_4_sheet_512x512_20.png",
        count: 20,
        hold_for: 6,
        impact_frame: 11,
        repeat: false,
        sfx: :event_neutral
      }
    }
  }.freeze

  attr_gtk
  attr :hp,
       :max_hp,
       :turn_start_timer,
       :attacked,
       :attacks,
       :attacked,
       :my_turn,
       :turn_ended_signal,
       :combat_stats

  def initialize()
    @enemy_id = "abyssal"
    super
    @shouts_enabled = false
    @w = 200
    @h = 200
    $enemy = self
    @combat_stats.set_stats(hp: 2)

    @animations =
      EnemyAnimationComponent.new(
        x: @x,
        y: @y,
        w: @w,
        h: @h,
        tx: 0,
        ty: 0,
        tw: 512,
        th: 512,
        animations: ANIMATIONS
      )

    @sprite = "sprites/triangle/equilateral/red.png"
    @name = "The Abyssal"
    @fled = false
    @attacks = {
      0 => {
        name: "Minor Damage",
        id: :one,
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 4,
              type: $DAMAGE_TYPES[:force]
            }
          }
        ]
      },
      1 => {
        name: "Scorch + Damage",
        id: :two,
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 6,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:scorch] => 4 }
        ]
      },
      2 => {
        name: "Medium Damage",
        id: :three,
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 7,
              type: $DAMAGE_TYPES[:force]
            }
          }
        ]
      },
      3 => {
        name: "Major Damage",
        id: :four,
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 10,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:scorch] => 1 }
        ]
      },
    }

    @attack_index = 0
    @max_attack_index = 3
  end

  def select_attack
    if @attack_index < @max_attack_index
      attack = @attacks[@attacks.keys[@attack_index]]
      @attack_index += 1
    else
      attack = @attacks[@attacks.keys[@attack_index]]
    end
    puts "ATTACK CHOSEN: #{attack[:name]}"
    attack
    @selected_attack = attack
  end

  def prefab
    enemy_sprite = @animations.prefab

    enemy_hp_label ||= {
      x: GTK.args.grid.w / 2,
      y: GTK.args.grid.h / 1.25 - 50 - (@w / 2),
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

    damage_flash_frame_index = nil
    claw_frame_index = nil
    if @damage_flash_tick
      damage_flash_frame_index =
        Numeric.frame_index(
          start_at: @damage_flash_tick,
          count: 4,
          hold_for: 1,
          repeat: false
        )
      claw_frame_index =
        Numeric.frame_index(
          start_at: @damage_flash_tick,
          count: 4,
          hold_for: 6,
          repeat: false
        )
    end

    if damage_flash_frame_index
      puts damage_flash_frame_index
      damage_flash_anim = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        a: 100,
        path: "sprites/damage_flash#{damage_flash_frame_index + 1}.png"
      }
      array << damage_flash_anim
    end

    if claw_frame_index
      claw_anim = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        path: "sprites/claw_attack#{claw_frame_index + 1}.png"
      }

      array << claw_anim
    end

    array
  end

  def calc_death_anim
    run_once(:death_animation) { @animations.play_animation(:death) }
  end

  def tick
    @animations.tick(x: @x, y: @y)
    @combat_stats.tick
    if @my_turn and not @combat_stats.dead
      calc

      unless @enemy.instance_variable_defined?(:@animations)
        if @attacked && @turn_start_timer.elapsed_time >= 1.0.seconds
          GTK.on_tick_count(Kernel.tick_count + 1) do
            $EVENT_BUS.publish(:enemy_animation_completed)
          end
        end
      end
    elsif @combat_stats.dead
      @combat_stats.hp = 1
      @fled = true
      end_turn
    end

    if !@combat_stats.dead
      @shout_component.tick
    else
      run_once(:publish_death) { $EVENT_BUS.publish(:enemy_died) }
      calc_death_anim
    end

    if @fled
      @x = @x.lerp(1050, 0.02)
      @w = @w.lerp(0, 0.03)
      @h = @h.lerp(0, 0.03)
    else
      calc_float
    end
  end
end
