class Wolf < Enemy
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
       :combat_stats

  def initialize()
    @enemy_id = "wolf"
    super
    $enemy = self
    @combat_stats =
      CombatStatsComponent.new(
        hp: 20,
        focus: 0,
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 270,
        resistances: [$DAMAGE_TYPES[:cold]]
      )
    @animations =
      EnemyAnimationComponent.new(
        enemy_id_sym: :wolf,
        x: @x,
        y: @y,
        w: @w,
        h: @h,
        tx: 0,
        ty: 0,
        tw: 128,
        th: 128
      )
    @sprite = "sprites/wolf-sheet-3.png"
    @name = "Wolf"
    @attacks = {
      70 => {
        name: "Basic Attack",
        attack_id: "a001",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 30,
              type: $DAMAGE_TYPES[:force]
            }
          }
        ]
      },
      20 => {
        name: "Power Attack",
        attack_id: "a002",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 10,
              type: $DAMAGE_TYPES[:force]
            }
          }
        ]
      },
      10 => {
        name: "Ultimate Attack",
        attack_id: "a003",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 20,
              type: $DAMAGE_TYPES[:force]
            },
            $CARD_TRAITS[:ward] => 15
          }
        ]
      }
    }
    $AUDIO_SERVICE.play_sound("#{@enemy_id}_start".to_sym)
  end

  def begin_turn
    super
    if !@combat_stats.dead
      $AUDIO_SERVICE.play_sound("#{@enemy_id}_attack".to_sym, rand_pitch: true)
    end
  end

  def tick
    frost_stacks = @combat_stats.statuses[$STATUS_TYPES[:FROST]]
    @animations.tick(x: @x, y: @y)
    if frost_stacks <= 0 && @my_turn &&
         @turn_start_timer.elapsed_time >= 0.7.seconds &&
         @turn_start_timer.elapsed_time < 0.8.seconds
      @animations.play_animation(:attack)
    end
    super
  end

  def calc_death_anim
    run_once(:death_animation) do 
      @animations.play_animation(:death)
      
    end
  end

  def attack
    @damage_flash_tick = Kernel.tick_count
    super
  end

  def prefab
    enemy_sprite = @animations.prefab

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
end
