class Wolf < Enemy
  attr_gtk
  attr :hp, :max_hp, :turn_start_timer, :attacked, :attacks, :attacked, :my_turn, :turn_ended_signal, :combat_stats

  def initialize()
    super
    $enemy = self
    @combat_stats = CombatStatsComponent.new(hp: 10, focus: 0, x: GTK.args.grid.w / 2, y: GTK.args.grid.h - 270)
    @sprite = "sprites/wolf.png"
    @name = "Wolf"
    @attacks = {
      70 => {
        name: "Basic Attack",
        damage: 1,
        attack_id: "a001",
      },
      20 => {
        name: "Power Attack",
        damage: 2,
        attack_id: "a002",
      },
      10 => {
        name: "Ultimate Attack",
        damage: 4,
        attack_id: "a003",
      }
    }
  end
end
