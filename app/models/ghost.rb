class Ghost < Enemy
  attr_gtk
  attr :hp, :max_hp, :turn_start_timer, :attacked, :attacks, :attacked, :my_turn, :turn_ended_signal, :combat_stats

  def initialize()
    super
    $enemy = self
    @combat_stats = CombatStatsComponent.new(hp:20, focus: 0, x: GTK.args.grid.w / 2, y: GTK.args.grid.h - 270)
    @sprite = "sprites/ghost.png"
    @name = "Ghost"
    @attacks = {
      70 => {
        name: "Basic Attack",
        damage: 3,
        attack_id: "a001",
      },
      20 => {
        name: "Power Attack",
        damage: 1,
        attack_id: "a002",
      },
      10 => {
        name: "Ultimate Attack",
        damage: 8,
        attack_id: "a003",
      }
    }
  end
end
