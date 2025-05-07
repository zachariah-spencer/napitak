class Enemy

    attr_accessor :hp, :max_hp, :turn_start_tick_count, :attacked, :attacks

    
    def initialize hp
        $enemy = self

        @turn_start_tick_count = 0
        @attacked = false
        @hp = hp
        @max_hp = hp

        @attacks = {
            70 => {
                name: "Basic Attack",
                damage: 1,
            },
            20 => {
                name: "Power Attack",
                damage: 2,
            },
            10 => {
                name: "Ultimate Attack",
                damage: 4,
            },
        }
    end

    def attack
        attack = select_attack
        puts attack
        status_label 80, (GTK.args.grid.h - 275), "#{attack[:damage]}", 255, 165, 0, 50
    
        $player.hp -= attack[:damage]
        if $player.hp <= 0
            puts "PLAYER DIED"
        end
    
        attacked = true
    end

    def select_attack
        rand_n = Numeric.rand(0..100)
        att_probs = @attacks.keys
        attack = 0
    
        if rand_n >= 0 and rand_n < att_probs[0]
          attack = @attacks[att_probs[0]]
        elsif rand_n  >= att_probs[0] and rand_n < ( att_probs[0] + att_probs[1] )
          attack = @attacks[att_probs[1]]
        elsif rand_n >= ( att_probs[0] + att_probs[1] ) and rand_n < ( att_probs[0]+ att_probs[1] + att_probs[2] )
          attack = @attacks[att_probs[2]]
        end
    
        attack
      end

end