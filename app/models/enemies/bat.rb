class Bat < Enemy
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
    @enemy_id = "bat"
    super
    $enemy = self
    @combat_stats =
      CombatStatsComponent.new(
        hp: 25,
        focus: 0,
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 270,
        resistances: [],
        vulnerabilities: [ $DAMAGE_TYPES[:heat] ],
        parent: self
      )
    @sprite = "sprites/isometric/black.png"
    @name = "Bat"
    @attacks = {
      50 => {
        name: "Basic Attack",
        attack_id: "a001",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 5,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:blind] => 10 }
        ]
      },
      20 => {
        name: "Power Attack",
        attack_id: "a002",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 5,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:blind] => 15 }
        ]
      },
      30 => {
        name: "Ultimate Attack",
        attack_id: "a003",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 10,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:blind] => 10 }
        ]
      }
    }

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
        #tile_x: (sprite_frame * 128),
        #tile_y: 0,
        #tile_w: 128,
        #tile_h: 128,
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
end
