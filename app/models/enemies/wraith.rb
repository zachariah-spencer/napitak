class Wraith < Enemy
  ANIMATIONS = {
    idle: {
      path: "sprites/wraith_idle_sheet_512x512_3.png",
      count: 3,
      hold_for: 45,
      repeat: true
    },
    hurt: {
      path: "sprites/dracolisk_hurt_512x512_sheet_18.png",
      count: 18,
      hold_for: 5,
      repeat: false
    },
    death: {
      path: "sprites/dracolisk_death_512x512_sheet_14.png",
      count: 14,
      hold_for: 8,
      repeat: false
    },
    attacks: {
      one: {
        path: "sprites/dracolisk_attack_1_512x512_sheet_12.png",
        count: 12,
        hold_for: 4,
        impact_frame:7,
        repeat: false,
        sfx: :event_neutral
      },
      two: {
        path: "sprites/dracolisk_attack_2_512x512_sheet_9.png",
        count: 9,
        hold_for: 4,
        impact_frame:4,
        repeat: false,
        sfx: :event_neutral
      },
      three: {
        path: "sprites/dracolisk_attack_3_512x512_sheet_7.png",
        count: 7,
        hold_for: 6,
        impact_frame:4,
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
    @enemy_id = "wraith"
    super
    $enemy = self
    @combat_stats.set_stats(hp: 20,
      vulnerabilities: [
          $DAMAGE_TYPES[:heat],
          $DAMAGE_TYPES[:cold],
          $DAMAGE_TYPES[:dark]
      ],
      resistances: [$DAMAGE_TYPES[:light]])

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

    @sprite = "sprites/wraith.png"
    @name = "Wraith"
    @attacks = {
      50 => {
        id: :one,
        name: "Damage",
        attack_id: "a001",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 5,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:frost] => 1 }
        ]
      },
      30 => {
        id: :two,
        name: "More Damage",
        attack_id: "a002",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 7,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:frost] => 1 }
        ]
      },
      20 => {
        id: :three,
        name: "Frost + Damage",
        attack_id: "a003",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 10,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:frost] => 2 }
        ]
      }
    }
  end

  def tick
    @animations.tick(x: @x, y: @y)
    super
  end

  def calc_death_anim
    run_once(:death_animation) { @animations.play_animation(:death) }
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
end
