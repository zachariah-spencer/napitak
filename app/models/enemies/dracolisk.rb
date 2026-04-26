class Dracolisk < Enemy
  ANIMATIONS = {
    idle: {
      path: "sprites/dracolisk_idle-sheet-512x512-3.png",
      count: 3,
      hold_for: 45,
      repeat: true
    },
    hurt: {
      path: "sprites/bat_hurt_512x512_sheet_17.png",
      count: 17,
      hold_for: 5,
      repeat: false
    },
    death: {
      path: "sprites/bat_death_512x512_sheet_9.png",
      count: 9,
      hold_for: 8,
      repeat: false
    },
    attacks: {
      basic: {
        path: "sprites/bat_attack_1_512x512_sheet_9.png",
        count: 9,
        hold_for: 6,
        impact_frame: 5,
        repeat: false,
        sfx: :bat_attack_1
      },
      special: {
        path: "sprites/bat_attack_2_512x512_sheet_13.png",
        count: 13,
        hold_for: 8,
        impact_frame: 5,
        repeat: false,
        sfx: :bat_attack_2
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
       :combat_stats,
       :is_boss

  def initialize()
    @enemy_id = "dracolisk"
    super
    @is_boss = true
    $enemy = self
    @combat_stats.set_stats(hp: 80,         resistances: [$DAMAGE_TYPES[:force]],
        vulnerabilities: [$DAMAGE_TYPES[:spark]])
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
    @sprite = "sprites/dracolisk.png"
    @name = "Crystal Dracolisk"
    @sprite_scale = 512
    @attacks = {
      45 => {
        name: "Basic Attack",
        attack_id: "a001",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 2,
              type: $DAMAGE_TYPES[:disease]
            }
          }
        ]
      },
      25 => {
        name: "Power Attack",
        id: :first,
        traits: [{ $CARD_TRAITS[:blight] => 1 }]
      },
      10 => {
        name: "Ultimate Attack",
        attack_id: "a003",
        traits: [{ $CARD_TRAITS[:blight] => 1 }, { $CARD_TRAITS[:ward] => 1 }]
      },
      10 => {
        name: "Ultimate Attack",
        attack_id: "a003",
        traits: [
          { $CARD_TRAITS[:blight] => 1 },
          {
            $CARD_TRAITS[:damage] => {
              amount: 1,
              type: $DAMAGE_TYPES[:disease]
            }
          }
        ]
      },
      5 => {
        name: "Ultimate Attack",
        attack_id: "a003",
        traits: [{ $CARD_TRAITS[:ward] => 4 }]
      },
      5 => {
        name: "Ultimate Attack",
        attack_id: "a003",
        traits: [
          { $CARD_TRAITS[:mend] => 1 },
          {
            $CARD_TRAITS[:damage] => {
              amount: 2,
              type: $DAMAGE_TYPES[:disease]
            }
          }
        ]
      }
    }
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
