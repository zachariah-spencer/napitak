class SparkleParticle
  attr :color
  def initialize(x:,y:,r:,g:,b:)
    @x = x
    @y = y
    @dx = 0
    @dy = 0
    
    @color = {
      r: r,
      g: g,
      b: b,
      a: 255
    }

    @particles = []
    60.times.each do
      @particles << particle(Numeric.rand(-20..20), Numeric.rand(-20..20))
    end

    @start_tick = Kernel.tick_count
  end

  def particle(dx, dy)
    {
      x: @x,
      y: @y,
      dx: dx,
      dy: dy,
      primitive_marker: :solid,
      w: Numeric.rand(1..3),
      h: Numeric.rand(1..3),
      r: @color.r,
      g: @color.g,
      b: @color.b,
      a: @color.a,
    }
  end

  def tick
    @color[:a] -= 2
    @particles.each do |particle| 
      particle.dy -= 0.5
      particle.dy = particle[:dy].clamp(-100.0, 100.0)

      particle.x = particle.x + particle.dx
      particle.y = particle.y + particle.dy
      particle.a = @color[:a]
    end
  end

  def prefab
    @particles
  end
end