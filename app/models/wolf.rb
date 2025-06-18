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
        attack_id: "a001",
        traits: [{$traits[:damage] => 1}]
      },
      20 => {
        name: "Power Attack",
        attack_id: "a002",
        traits: [{$traits[:damage] => 2}]
      },
      10 => {
        name: "Ultimate Attack",
        attack_id: "a003",
        traits: [{$traits[:damage] => 4}]
      }
    }
  end
end
