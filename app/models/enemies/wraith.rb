class Wraith < Enemy
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
    @sprite = "sprites/wraith.png"
    @name = "Wraith"
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
          },
          { $CARD_TRAITS[:frost] => 1 }
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
              amount: 4,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:frost] => 1 }
        ]
      }
    }
  end
end
