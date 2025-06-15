class Enemy
  attr_gtk
  attr :hp, :max_hp, :turn_start_tick_count, :attacked, :attacks, :attacking

  def initialize(hp)
    $enemy = self

    @turn_start_tick_count = 0
    @attacked = false
    @attacking = false
    @hp = hp
    @max_hp = hp

    @attacks = {
      70 => {
        name: "Basic Attack",
        damage: 1
      },
      20 => {
        name: "Power Attack",
        damage: 2
      },
      10 => {
        name: "Ultimate Attack",
        damage: 4
      }
    }
  end

  def attack
    attack = select_attack
    puts "ANIMS #{$animations[:basic_attack]}"
    $animation_manager.queue_animation(:basic_attack, lock_input: true)
    @attacking = true
    status_label(
      80,
      (GTK.args.grid.h - 275),
      "#{attack[:damage]}",
      255,
      165,
      0,
      100
    )
    $player.hp -= attack[:damage]
    @attacked = true

    if $player.hp <= 0
    $player.hp = 0
      return true
    else
      return false
    end
  end

  def select_attack
    rand_n = Numeric.rand(0..100)
    att_probs = @attacks.keys
    attack = 0

    if rand_n >= 0 and rand_n < att_probs[0]
      attack = @attacks[att_probs[0]]
    elsif rand_n >= att_probs[0] and rand_n < (att_probs[0] + att_probs[1])
      attack = @attacks[att_probs[1]]
    elsif rand_n >= (att_probs[0] + att_probs[1]) and
          rand_n < (att_probs[0] + att_probs[1] + att_probs[2])
      attack = @attacks[att_probs[2]]
    end

    attack
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    case layer_num
    when 0
      return l0
    when 1
      enemy_sprite ||= {
        x: GTK.args.grid.w / 2 - 100,
        y: GTK.args.grid.h - 250,
        w: 200,
        h: 200,
        path: "sprites/wolf.png",
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
        text: "#{@hp}/#{@max_hp}",
        primitive_marker: :label
      }

      l1 << [enemy_sprite, enemy_hp_label]
      return l1
    when 2
      return l2
    when 3
      return l3
    when 4
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end
end
