# frozen_string_literal: true

class AnimationManager
  attr_gtk
  attr_accessor :player_ready_at

  def initialize(animations = $animations)
    $animation_manager = self
    @animations = animations
    @queue = []
    @current = nil
    @current_frame_index = 0
    @frame_started_at = 0
    @player_ready_at = 0
  end

  def input_locked?
    Kernel.tick_count < @player_ready_at
  end

  def queue_animation(id, lock_input: false)
    anim = @animations[id]
    return unless anim

    duration = anim[:frames].length * anim[:frame_length]
    ready_at = Kernel.tick_count + duration
    @queue << { id: id, data: anim, lock_input: lock_input, ready_at: ready_at }
    @player_ready_at = ready_at if lock_input
  end

  def tick
    start_next_animation if @current.nil? && !@queue.empty?
    return unless @current

    if Kernel.tick_count - @frame_started_at >= @current[:data][:frame_length]
      @current_frame_index += 1
      @frame_started_at = Kernel.tick_count
      particles = @current[:data][:particle_frames][@current_frame_index]
      particles&.each do |p|
        GameUtils.status_label(
          p[:x],
          p[:y],
          p[:text],
          p[:r],
          p[:g],
          p[:b],
          p[:scale]
        )
      end
      if @current_frame_index >= @current[:data][:frames].length
        finish_current_animation
      end
    end
  end

  def render(layer = 0)
    return [] unless @current
    frame_path = @current[:data][:frames][@current_frame_index]
    rect = @current[:data][:rect]
    [
      {
        x: rect.x,
        y: rect.y,
        w: rect.w,
        h: rect.h,
        path: frame_path,
        primitive_marker: :sprite
      }
    ]
  end

  private

  def start_next_animation
    @current = @queue.shift
    @current_frame_index = 0
    @frame_started_at = Kernel.tick_count
  end

  def finish_current_animation
    @player_ready_at = Kernel.tick_count if @current[:lock_input]
    @current = nil
  end
end
