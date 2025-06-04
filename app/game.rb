class Game
  attr_gtk
  attr

  def initialize
    @scene = ""
    @scene_ref = nil

    # keeps track of whether an entity with a specific entity_id has been created already
    @created_entity_ids = []
    # currently list of status_labels to render to the screen at any given frame
    @status_labels = []
    # keeps track of whether a render target for the specific number has been created already
    @created_prefabs = {}
    # the game's official instantiation of a Player for an individual game.
    @player = nil
    # the game's official instantiation of a RecipeBook, persists between runs
    @recipe_book = RecipeBook.new()

    new_run
    # change_scene(prev_sc: "", next_sc: "alchemy_table")
    change_scene(prev_sc: "", next_sc: "rewards_screen")
  end

  def new_run
    @player = Player.new()

    4.times { @player.potions.add(gen_new_card("p001")) }
  end

  def change_scene(prev_sc:, next_sc:)
    @scene_ref.cleanup if prev_sc != ""
    @scene = next_sc

    case @scene
    when "combat"
      @scene_ref = Combat.new()
    when "alchemy_table"
      @scene_ref = AlchemyTable.new(max_uses: 3)
    when "alchemy_lab"
      @scene_ref = AlchemyLab.new(max_uses: 10, max_ingredients: 10)
    when "rewards_screen"
      @scene_ref = RewardsScreen.new()
    end
  end

  def tick
    if @scene_ref
      @scene_ref.args = args
      @scene_ref.tick
    end

    render
    calc_particles
  end

  def render
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    if @scene_ref
      l0 << @scene_ref.render(0)
      l1 << @scene_ref.render(1)
      l2 << @scene_ref.render(2)
      l3 << @scene_ref.render(3)
      l4 << @scene_ref.render(4)
    end

    # for each particle, construct a prefab
    l4 << @status_labels.map { |particle| status_label_prefab particle }

    outputs.primitives << [l0, l1, l2, l3, l4]
  end

  def calc_particles
    # process each particle setting their alpha
    # make them spin, and set their y value
    @status_labels.each do |particle|
      particle.a -= 5
      particle.angle += 10
      particle.y += 3
    end

    # reject all particles with an alpha less than equal to 0
    @status_labels.reject! { |particle| particle.a <= 0 }
  end

  def create_particle_rt!(number, r, g, b, scale)
    # if the render target for the number has already been created
    # (and cached). return/exit early since we don't want to bust the
    # texture that's already been created for us
    return @created_prefabs[number] if @created_prefabs[number]
    path = number.to_s

    # if it hasn't been created, then create a RT with the name equal to
    # to the number. add it to the lookup of created_prefabs
    @created_prefabs[number] = path

    # set RT properties
    outputs[path].w = scale
    outputs[path].h = scale
    outputs[path].background_color = [0, 0, 0, 0]

    # add the label to the render target
    outputs[path].labels << {
      x: 15,
      y: 15,
      text: number.to_s,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: scale,
      r: r,
      g: g,
      b: b
    }
  end

  def status_label(x, y, t, r, g, b, scale)
    @status_labels << {
      x: x,
      y: y,
      created_at: Kernel.tick_count,
      text: t,
      a: 255,
      angle: 0,
      scale: scale / 2,
      r: r,
      g: g,
      b: b
    }
  end

  # returns the particle prefab
  def status_label_prefab(s_l)
    # create the rt for the particle (this will return/no-op if the RT
    # has already been created)
    path = create_particle_rt! s_l.text, s_l.r, s_l.g, s_l.b, s_l.scale

    # if the particle was created this frame, skip its render
    # since the RT won't be processed until the next tick
    if s_l.created_at == Kernel.tick_count
      nil
    else
      # return a prefab that represents the RT/label as a sprite
      {
        x: s_l.x,
        y: s_l.y,
        w: s_l.scale,
        h: s_l.scale,
        anchor_x: 0.5,
        anchor_y: 0.5,
        path: path,
        r: s_l.r,
        g: s_l.g,
        b: s_l.b,
        a: s_l.a,
        angle: s_l.angle
      }
    end
  end
end
