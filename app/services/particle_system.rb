# frozen_string_literal: true

module Services
  class ParticleSystem
    STATUS_LABEL_QUEUE_COOLDOWN = 0.2.seconds

    def initialize
      reset!
    end

    def reset!
      @status_labels = []
      @sparkle_particles = []
      @status_labels_queue = []
      @status_label_queue_count = Kernel.tick_count
      @created_prefabs = {}
    end

    def reset_scene_particles!
      @sparkle_particles.clear
    end

    def queue_status_label(x, y, text, r, g, b, scale)
      text_w, text_h = GTK.calcstringbox(text, scale)
      padding = 4
      label_hash = {
        x: x,
        y: y,
        w: text_w + padding * 2,
        h: text_h + padding * 2,
        created_at: Kernel.tick_count,
        text: text,
        a: 255,
        angle: 0,
        scale: scale,
        r: r,
        g: g,
        b: b,
        font: $FONT,
        angle_anchor_x: 0.5,
        angle_anchor_y: 0.5,
        angle_mod: Numeric.rand(-0.2..0.2)
      }
      @status_labels_queue << label_hash
    end

    def spawn_sparkle(x:, y:, r:, g:, b:)
      @sparkle_particles << SparkleParticle.new(x: x, y: y, r: r, g: g, b: b)
    end

    def process_queue!
      return if @status_labels_queue.empty?
      return unless @status_label_queue_count.elapsed_time >= STATUS_LABEL_QUEUE_COOLDOWN

      new_label = @status_labels_queue.shift
      new_label[:created_at] = Kernel.tick_count
      @status_label_queue_count = Kernel.tick_count
      @status_labels << new_label
    end

    def advance_particles!
      @status_labels.each do |particle|
        particle[:a] -= 4
        particle[:angle] += particle[:angle_mod]
        particle[:y] += 1.5
      end

      @sparkle_particles.each(&:tick)

      @status_labels.reject! { |particle| particle[:a] <= 0 }
      @sparkle_particles.reject! { |particle| particle.color[:a] <= 0 }
    end

    def sparkle_prefabs
      @sparkle_particles.map(&:prefab)
    end

    def status_label_prefabs
      @status_labels.each_with_object([]) do |particle, prefabs|
        prefab = status_label_prefab(particle)
        prefabs << prefab if prefab
      end
    end

    private

    def status_label_prefab(label)
      path = ensure_render_target!(
        label[:text],
        label[:r],
        label[:g],
        label[:b],
        label[:scale],
        label[:w],
        label[:h]
      )

      return nil if label[:created_at] == Kernel.tick_count

      {
        x: label[:x],
        y: label[:y],
        w: label[:w],
        h: label[:h],
        anchor_x: 0.5,
        anchor_y: 0.5,
        angle_anchor_x: 0.5,
        angle_anchor_y: 0.5,
        path: path,
        r: label[:r],
        g: label[:g],
        b: label[:b],
        a: label[:a],
        font: $FONT,
        angle: label[:angle]
      }
    end

    def ensure_render_target!(text, r, g, b, scale, w, h)
      return @created_prefabs[text] if @created_prefabs[text]

      path = text.to_s
      outputs = GTK.args.outputs
      outputs[path].w = w
      outputs[path].h = h
      outputs[path].background_color = [0, 0, 0, 0]
      outputs[path].labels << {
        x: w / 2,
        y: h / 2,
        text: text.to_s,
        font: $FONT,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: scale,
        r: r,
        g: g,
        b: b
      }

      @created_prefabs[text] = path
    end
  end
end
