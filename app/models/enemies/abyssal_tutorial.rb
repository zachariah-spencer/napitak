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
    @enemy_id = "abyssal"
    super
    @w = 200
    @h = 200
    $enemy = self
    @combat_stats =
      CombatStatsComponent.new(
        hp: 100,
        focus: 0,
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 270
      )
    @sprite = "sprites/triangle/equilateral/blue.png"
    @name = "The Abyssal"
    @fled = false
    @attacks = {
      0 => {
        name: "Attack 1",
        attack_id: "a001",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 2,
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
              amount: 3,
              type: $DAMAGE_TYPES[:force]
            }
          },
          { $CARD_TRAITS[:scorch] => 4 }
        ]
      },
      2 => {
        name: "Attack 3",
        attack_id: "a003",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 4,
              type: $DAMAGE_TYPES[:force]
            }
          },
        ]
      },
      3 => {
        name: "Attack 4",
        attack_id: "a003",
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 5,
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
              amount: 6,
              type: $DAMAGE_TYPES[:force]
            }
          }
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

  def prefab
    enemy_sprite ||= {
      x: @x,
      y: @y,
      angle: @ang,
      w: @w,
      h: @h,
      path: @sprite,
      primitive_marker: :sprite
    }

    enemy_hp_label ||= {
      x: GTK.args.grid.w / 2,
      y: GTK.args.grid.h - 270,
      alignment_enum: 1,
      size_enum: 5,
      r: 150,
      g: 0,
      b: 0,
      text: "#{@combat_stats.hp}/#{@combat_stats.max_hp}",
      primitive_marker: :label
    }

    [enemy_sprite, enemy_hp_label]
  end

  def tick
    @combat_stats.tick
    if @my_turn and not @combat_stats.dead
      calc
    elsif @combat_stats.dead
      @combat_stats.hp = 1
      @fled = true
      end_turn
    end

    if @fled
      @x = @x.lerp(1050, 0.02)
      @w = @w.lerp(0, 0.03)
      @h = @h.lerp(0, 0.03)
    else
      calc_float
    end
  end
end
