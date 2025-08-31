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
    @combat_stats.set_stats(hp: 1)
    @sprite = "sprites/triangle/equilateral/red.png"
    @name = "The Abyssal"
    @fled = false
    @attacks = {
      0 => {
        name: "Attack 1",
        id: :one,
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
        id: :two,
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
        id: :three,
        traits: [
          {
            $CARD_TRAITS[:damage] => {
              amount: 4,
              type: $DAMAGE_TYPES[:force]
            }
          }
        ]
      },
      3 => {
        name: "Attack 4",
        id: :four,
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
        id: :five,
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
    @selected_attack = attack
  end

  def prefab
    sprite_frame =
      0.frame_index(
        count: 3,
        hold_for: 30,
        repeat: true,
        repeat_index: 0,
        tick_count_override: Kernel.tick_count
      )
    enemy_sprite ||= {
      x: @x,
      y: @y,
      angle: @ang,
      w: @w,
      h: @h,
      r: @r,
      path: @sprite,
      #tile_x: (sprite_frame * 128),
      #tile_y: 0,
      #tile_w: 128,
      #tile_h: 128,
      primitive_marker: :sprite
    }

    enemy_hp_label ||= {
      x: GTK.args.grid.w / 2,
      y: GTK.args.grid.h - 270,
      alignment_enum: 1,
      size_px: 20,
      r: 150,
      g: 0,
      b: 0,
      text: "#{@combat_stats.hp} / #{@combat_stats.max_hp}",
      font: $FONT,
      primitive_marker: :label
    }

    if !@combat_stats.dead && @shout_component.prefab
      enemy_shout = @shout_component.prefab
    else
      enemy_shout = nil
    end

    array = [enemy_sprite, enemy_hp_label, @combat_stats.prefab]
    array << enemy_shout if enemy_shout
    array
  end

  def tick
    @combat_stats.tick
    if @my_turn and not @combat_stats.dead
      calc

      unless @enemy.instance_variable_defined?(:@animations)
        if @attacked && @turn_start_timer.elapsed_time >= 1.0.seconds
          GTK.on_tick_count(Kernel.tick_count + 1) do
            $EVENT_BUS.publish(:enemy_animation_completed)
          end
        end
      end
    elsif @combat_stats.dead
      @combat_stats.hp = 1
      @fled = true
      end_turn
    end

    if !@combat_stats.dead
      @shout_component.tick
    else
      run_once(:publish_death) { $EVENT_BUS.publish(:enemy_died) }
      # calc_death_anim
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
