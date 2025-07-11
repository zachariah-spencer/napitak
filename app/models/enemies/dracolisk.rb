class Dracolisk < Enemy
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
    @combat_stats =
      CombatStatsComponent.new(
        hp: 2,
        focus: 0,
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 270,
        resistances: []
      )
    @sprite = "sprites/triangle/equilateral/red.png"
    @name = "Crystal Dracolisk"
    @attacks = {
      70 => {
        name: "Basic Attack",
        attack_id: "a001",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 1,
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
              amount: 2,
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
              amount: 2,
              type: $DAMAGE_TYPES[:force]
            }
          }
        ]
      }
    }
  end
end
