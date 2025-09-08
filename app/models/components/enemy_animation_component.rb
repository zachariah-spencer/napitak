class EnemyAnimationComponent
  def initialize(x:, y:, w:, h:, tx:, ty:, tw:, th:, enemy_id_sym:)
    @x = x
    @y = y
    @w = w
    @h = h
    @tx = tx
    @ty = ty
    @tw = tw
    @th = th
    @dead = false

    # Load anims from global hash and do some light parsing to eliminate organizational sub-hashes so we have flat k,v pairs to work with
    @animations = $ENEMY_ANIMATIONS[enemy_id_sym]
      .merge($ENEMY_ANIMATIONS[enemy_id_sym][:attacks])
      .reject! { |id, anim| id == :attacks}

    @current_animation = :idle
    @playing_one_shot = false
    @animation_impacted = false
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
      @previous_animation = animation

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
        $EVENT_BUS.publish(:enemy_animation_completed, { id: @current_animation }) if @playing_one_shot
        @playing_one_shot = false
        return(@animations[@current_animation][:count] - 1)
      end
    end
  end

  def impact_frame_reached?
    @current_animation && calc_frame_index && calc_frame_index == @animations[@current_animation][:impact_frame] && !@animation_impacted && @playing_one_shot
  end

  def anim_has_impact_frame?
    @animations[@current_animation].key?(:impact_frame)
  end

  def prefab()
    return unless @current_animation

    if @current_animation && !(calc_frame_index) && !@dead
      just_finished = @current_animation
      @current_animation = :idle
      $EVENT_BUS.publish(:enemy_animation_completed, id: just_finished) if @playing_one_shot
      @playing_one_shot = false
      @animation_impacted = false
    elsif calc_frame_index && anim_has_impact_frame? && impact_frame_reached?
      @animation_impacted = true
      $EVENT_BUS.publish(:enemy_animation_impacted, id: @current_animation)
      GameUtils.camera_shake(intensity: 15, duration: 0.5.seconds)
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
