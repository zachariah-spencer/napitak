class AbyssalTutorial < Enemy
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
    super
    $enemy = self
    @combat_stats =
      CombatStatsComponent.new(
        hp: 30,
        focus: 0,
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 270
      )
    @sprite = "sprites/triangle/equilateral/red.png"
    @name = "The Abyssal"
    @attacks = {
      0 => {
        name: "Attack 1",
        attack_id: "a001",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 3,
              type: $DAMAGE_TYPES[:force]
            }
          }
        ]
      },
      1 => {
        name: "Attack 2",
        attack_id: "a002",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 1,
              type: $DAMAGE_TYPES[:force]
            }
          },
          {
            $CARD_TRAITS[:scorch] => 4
          }
        ]
      },
      2 => {
        name: "Attack 3",
        attack_id: "a003",
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
      3 => {
        name: "Attack 4",
        attack_id: "a003",
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
      4 => {
        name: "Attack 5",
        attack_id: "a003",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 10,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:scorch] => 1 }
        ]
      }
    }

    @attack_index = 0
    @max_attack_index = 4
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
  end
end
