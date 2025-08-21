class Mawfiend < Enemy
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
    @enemy_id = "mawfiend"
    super
    $enemy = self
    @combat_stats =
      CombatStatsComponent.new(
        hp: 12,
        focus: 0,
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 270,
        resistances: [$DAMAGE_TYPES[:heat]],
        vulnerabilities: [$DAMAGE_TYPES[:cold]],
        parent: self
      )
    @sprite = "sprites/triangle/equilateral/orange.png"
    @name = "Abyssal Mawfiend"
    @attacks = {
      60 => {
        name: "Basic Attack",
        attack_id: "a001",
        traits: [
          { $CARD_TRAITS[:damage] => { amount: 1, type: $DAMAGE_TYPES[:heat] } }
        ]
      },
      20 => {
        name: "Power Attack",
        attack_id: "a002",
        traits: [{ $CARD_TRAITS[:scorch] => 2 }]
      },
      10 => {
        name: "Ultimate Attack",
        attack_id: "a003",
        traits: [
          { $CARD_TRAITS[:scorch] => 2 },
          { $CARD_TRAITS[:damage] => { amount: 1, type: $DAMAGE_TYPES[:heat] } }
        ]
      },
      10 => {
        name: "Ultimate Attack",
        attack_id: "a003",
        traits: [
          { $CARD_TRAITS[:scorch] => 2 },
          { $CARD_TRAITS[:ward] => 1 },
          { $CARD_TRAITS[:damage] => { amount: 1, type: $DAMAGE_TYPES[:heat] } }
        ]
      }
    }
  end
end
