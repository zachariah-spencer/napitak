class EnemyAI
  attr_gtk

  def initialize(enemy, on_turn_end: nil)
    @enemy = enemy
    @on_turn_end = on_turn_end
  end

  def tick
    @enemy.tick
    if @enemy.turn_over?
      @on_turn_end&.call
    end
  end

  def enemy
    @enemy
  end
end
