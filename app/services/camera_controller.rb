# frozen_string_literal: true

module Services
  class CameraController
    attr_reader :camera_state

    def initialize
      reset!
    end

    def reset!
      @camera_state = { x: 0.0, y: 0.0, zoom: 1.0 }
      @shake_active = false
      @shake_amp = 0.0
      @shake_start_tick = 0
      @shake_end_tick = 0
      @shake_include_ui = false
      @shake_offset_x = 0.0
      @shake_offset_y = 0.0
    end

    def shake(intensity: 8.0, duration: 0.3.seconds, include_ui: false)
      @shake_active = true
      @shake_amp = intensity.to_f
      @shake_start_tick = Kernel.tick_count
      @shake_end_tick = Kernel.tick_count + duration.to_i
      @shake_include_ui = include_ui
    end

    def shake_includes_ui?
      @shake_include_ui
    end

    def update
      if @shake_active
        if Kernel.tick_count >= @shake_end_tick
          @shake_active = false
          @shake_offset_x = 0.0
          @shake_offset_y = 0.0
        else
          total = (@shake_end_tick - @shake_start_tick).to_f
          elapsed = (Kernel.tick_count - @shake_start_tick).to_f
          t = (elapsed / total).clamp(0.0, 1.0)
          falloff = 1.0 - t
          amp = @shake_amp * falloff
          @shake_offset_x = Numeric.rand(-amp..amp)
          @shake_offset_y = Numeric.rand(-amp..amp)
        end
      else
        @shake_offset_x = 0.0
        @shake_offset_y = 0.0
      end
    end

    def apply_to_renderables!(renderables, apply_world_transform:, apply_shake: true)
      return if renderables.nil?

      renderables.map! do |renderable|
        if renderable.is_a?(Array)
          apply_to_renderables!(
            renderable,
            apply_world_transform: apply_world_transform,
            apply_shake: apply_shake
          )
          renderable
        elsif renderable.is_a?(Hash)
          apply_to_hash!(
            renderable,
            apply_world_transform: apply_world_transform,
            apply_shake: apply_shake
          )
        else
          renderable
        end
      end
    end

    private

    def apply_to_hash!(hash, apply_world_transform:, apply_shake: true)
      return hash if hash.nil?

      offset_x = 0.0
      offset_y = 0.0
      if apply_world_transform
        offset_x -= @camera_state[:x].to_f
        offset_y -= @camera_state[:y].to_f
      end

      if apply_shake
        offset_x += @shake_offset_x
        offset_y += @shake_offset_y
      end

      hash[:x] = hash[:x].to_f + offset_x if hash.key?(:x)
      hash[:y] = hash[:y].to_f + offset_y if hash.key?(:y)
      hash[:x1] = hash[:x1].to_f + offset_x if hash.key?(:x1)
      hash[:y1] = hash[:y1].to_f + offset_y if hash.key?(:y1)
      hash[:x2] = hash[:x2].to_f + offset_x if hash.key?(:x2)
      hash[:y2] = hash[:y2].to_f + offset_y if hash.key?(:y2)
      hash
    end
  end
end
