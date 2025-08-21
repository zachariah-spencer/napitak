class PotionAnimationComponent
  def initialize(x:, y:, w:, h:, tx:, ty:, tw:, th:)
    @x = x
    @y = y
    @w = w
    @h = h
    @tx = tx
    @ty = ty
    @tw = tw
    @th = th

    @current_animation = nil
    @playing_one_shot = false
    @animation_impacted = false
    @sprite_frame_start_ticks = {
      idle: 0,
      attack: 0,
    }
  end

  def play_animation(animation)
    return if !animation
    @current_animation = animation
    @sprite_frame_start_ticks[@current_animation[:id]] = Kernel.tick_count
    @playing_one_shot = true
  end

  def calc_frame_index
      Numeric.frame_index(
                    start_at: @sprite_frame_start_ticks[@current_animation[:id]],
                    count: @current_animation[:count],
                    hold_for: @current_animation[:hold_for],
                    repeat: @current_animation[:repeat],
                  )
  end

  def impact_frame_reached?
    @current_animation && calc_frame_index && calc_frame_index == @current_animation[:impact_frame] && !@animation_impacted && @playing_one_shot
  end

  def prefab()
    return unless @current_animation

    if !(calc_frame_index)
      $EVENT_BUS.publish(:potion_animation_completed, id: @current_animation[:id]) if @playing_one_shot
      @current_animation = nil
      @animation_impacted = false
      @playing_one_shot = false
      return
    elsif impact_frame_reached?
      @animation_impacted = true
      $EVENT_BUS.publish(:potion_animation_impacted, id: @current_animation[:id])
    end
    

    sprite = {
      x: @x,
      y: @y,
      w: @w,
      h: @h,
      path: $PIDS[@current_animation[:id]][:cast_animation][:path],
      tile_x: (calc_frame_index * @tw),
      tile_y: @th * 0,
      tile_w: @tw,
      tile_h: @th,
      primitive_marker: :sprite
    }

    sprite
  end

end