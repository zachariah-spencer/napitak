class EnemyAnimationComponent
  def initialize(x:, y:, w:, h:, tx:, ty:, tw:, th:)
    @x = x
    @y = y
    @w = w
    @h = h
    @tx = tx
    @ty = ty
    @tw = tw
    @th = th
    @dead = false

    # FIXME: Refactor to pull from global hash
    @animations = {
      idle: {
        path: "sprites/wolf-sheet-3.png",
        count: 3,
        hold_for: 30,
        repeat: true
      },
      attack: {
        path: "sprites/wolf_attack1-sheet-4.png",
        count: 4,
        hold_for: 10,
        repeat: false
      },
      death: {
        path: "sprites/wolf_death-sheet-15.png",
        count: 15,
        hold_for: 5,
        repeat: false
      }
    }

    @current_animation = :idle
    @playing_one_shot = false
    @sprite_frame_start_ticks = { idle: 0, attack: 0 }
  end

  def tick(x: @x, y: @y)
    @x = x
    @y = y
  end

  def play_animation(animation)
    return if !@animations.keys.include?(animation)
    if animation != :idle
      @sprite_frame_start_ticks[animation] = Kernel.tick_count
      @playing_one_shot = true

      @dead = true if animation == :death
    end
    @current_animation = animation
  end

  def calc_frame_index
    return 0 unless @sprite_frame_start_ticks && @current_animation
    if !@dead
      Numeric.frame_index(
        start_at: @sprite_frame_start_ticks[@current_animation],
        count: @animations[@current_animation][:count],
        hold_for: @animations[@current_animation][:hold_for],
        repeat: @animations[@current_animation][:repeat]
      )
    else
      f_i =
        Numeric.frame_index(
          start_at: @sprite_frame_start_ticks[@current_animation],
          count: @animations[@current_animation][:count],
          hold_for: @animations[@current_animation][:hold_for],
          repeat: @animations[@current_animation][:repeat]
        )

      if f_i
        return f_i
      else
        $EVENT_BUS.publish(:enemy_animation_completed) if @playing_one_shot
        @playing_one_shot = false
        return(@animations[@current_animation][:count] - 1)
      end
    end
  end

  def prefab()
    if !(calc_frame_index) && !@dead
      @current_animation = :idle
      $EVENT_BUS.publish(:enemy_animation_completed) if @playing_one_shot
      @playing_one_shot = false
    end
    enemy_sprite = {
      x: @x,
      y: @y,
      w: @w,
      h: @h,
      path: @animations[@current_animation][:path],
      tile_x: (calc_frame_index * @tw),
      tile_y: @th * 0,
      tile_w: @tw,
      tile_h: @th,
      primitive_marker: :sprite
    }

    enemy_sprite
  end
end
