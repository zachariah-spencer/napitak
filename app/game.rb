# frozen_string_literal: true

class Game
  attr_gtk
  attr :tutorials, :scene

  def initialize
    @autosaved = false

    @scene = $files.save_data&.[]("scene")
    @scene_ref = nil
    @paused_scene_ref = nil
    @paused = false
    @pause_button_pos = 200 + 20
    AnimationManager.new

    # keeps track of whether an entity with a specific entity_id has been created already
    @created_entity_ids = []
    # currently list of status_labels to render to the screen at any given frame
    @status_labels = []
    # queue of labels to render to the screen
    @status_labels_queue = []
    @new_status_label_queued = false
    @status_label_queue_count = Kernel.tick_count
    # keeps track of whether a render target for the specific number has been created already
    @created_prefabs = {}
    # the game's official instantiation of a Player for an individual game.
    @player = Player.new()
    # the game's official instantiation of a RecipeBook, persists between runs
    @recipe_book = RecipeBook.new()
    @encounter_manager = EncounterManager.new()

    @player.load_inventory_data
    @player.load_upgrades_data

    is_mid_run = $files.save_data&.[]("mid_run")
    encounters_completed = $files.save_data&.[]("encounters_completed")

    is_mid_run ? change_scene(prev_sc: "", next_sc: @scene) : new_run
  end

  # reset vars for new run
  def new_run
    $files.save_data["mid_run"] = true
    $encounter_manager.reset!
    @player.reset!
    change_scene(prev_sc: "", next_sc: "map")
  end

  def change_scene(prev_sc:, next_sc:, args: [])
    @scene_ref.cleanup if prev_sc != ""
    @scene = next_sc

    if next_sc == "run_summary" || next_sc == "meta_shop"
      @pause_button_pos = 15
    else
      @pause_button_pos = 200 + 15
    end

    case @scene
    when "combat"
      @scene_ref = Combat.new(args[0])
    when "alchemy_table"
      @scene_ref = AlchemyTable.new(max_uses: $player.alchemy_table_uses)
    when "alchemy_lab"
      @scene_ref =
        AlchemyLab.new(
          max_uses: 10,
          max_ingredients: $player.starting_inventory_size
        )
    when "rewards_screen"
      @scene_ref = RewardsScreen.new(picks: $player.reward_picks)
    when "map"
      @scene_ref = Map.new()
    when "run_summary"
      @scene_ref = RunSummary.new()
    when "meta_shop"
      @scene_ref = MetaShop.new()
    end

    $files.save_data["scene"] = next_sc
  end

  def toggle_pause(paused_scene_ref: nil)
    @paused = !@paused

    if @paused
      @scene = "pause_menu"
      @paused_scene_ref = paused_scene_ref if paused_scene_ref
      @scene_ref = PauseMenu.new
    else
      @scene = @paused_scene_ref.sc_id
      @scene_ref.cleanup
      @scene_ref = @paused_scene_ref
    end
  end

  def handle_pause
    if GTK.args.inputs.keyboard.key_down.escape or
         (
           GTK.args.inputs.mouse.click and
             Geometry.intersect_rect?(
               GTK.args.inputs.mouse,
               pause_btn(x: @pause_button_pos)
             )
         )
      toggle_pause(paused_scene_ref: @scene_ref)
    end
  end

  def tick
    handle_pause

    if @new_status_label_queued &&
         @status_label_queue_count.elapsed_time >= 0.75.seconds
      new_label = @status_labels_queue.shift
      new_label.created_at = Kernel.tick_count
      @status_labels << new_label
      @new_status_label_queued = false
    end

    if @scene_ref
      @scene_ref.args = args
      @scene_ref.tick
    end

    $animation_manager.tick if $animation_manager
    render
    calc_particles

    if GTK.args.inputs.keyboard.key_down.p
      puts "\n\nPREV POT LOADOUT\n-------------------------------------------\n"
      $player.prev_loadout_potions.all_cards.each { |c| puts c.id }

      puts "\n\nCURRENT POTS\n-------------------------------------------\n"
      $player.potions.all_cards.each { |c| puts c.id }
    end

    # puts $files.save_data to file
    if (GTK.quit_requested? && !@autosaved)
      $files.write
      puts "WRITING SAVE DATA TO FILE"
    end
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

    # render any active animations
    l2 << $animation_manager.render if $animation_manager

    # for each particle, construct a prefab
    l4 << @status_labels.map { |particle| status_label_prefab particle }

    l4 << {
      x: 550,
      y: 350,
      text: "Test",
      size_px: 20,
      r: 255,
      g: 255,
      b: 255,
      primitive_marker: :label
    }
    outputs.primitives << [l0, l1, l2, l3, l4]

    outputs.primitives << pause_btn(x: @pause_button_pos) if not @paused

    InfoBox.render(GTK.args) if not @paused
  end

  def pause_btn(x: 195, y: GTK.args.grid.h - 45, w: 32, h: 32)
    { x: x, y: y, w: w, h: h, angle: 0, path: "sprites/pause_button.png" }
  end

  def calc_particles
    # process each particle setting their alpha
    # make them spin, and set their y value
    @status_labels.each do |particle|
      particle.a -= 5
      particle.angle += 0.5 # / (particle.scale * 0.2)
      particle.y += 3
    end

    # reject all particles with an alpha less than equal to 0
    @status_labels.reject! { |particle| particle.a <= 0 }
  end

  def status_label(x, y, t, r, g, b, scale)
    text_w, text_h = GTK.calcstringbox(t, scale)
    padding = 4
    w = text_w + padding * 2
    h = text_h + padding * 2

    @new_status_label_queued = true
    @status_labels_queue << {
      x: x,
      y: y,
      w: w,
      h: h,
      created_at: Kernel.tick_count,
      text: t,
      a: 255,
      angle: 0,
      scale: scale,
      r: r,
      g: g,
      b: b,
      angle_anchor_x: 0.5,
      angle_anchor_y: 0.5
    }
  end

  def create_particle_rt!(text, r, g, b, scale, w, h)
    # if the render target for the number has already been created
    # (and cached). return/exit early since we don't want to bust the
    # texture that's already been created for us
    return @created_prefabs[text] if @created_prefabs[text]
    path = text.to_s

    # if it hasn't been created, then create a RT with the name equal to
    # to the number. add it to the lookup of created_prefabs
    @created_prefabs[text] = path
    padding = 4

    # set RT properties
    outputs[path].w = w
    outputs[path].h = h
    outputs[path].background_color = [0, 0, 0, 0]

    # add the label to the render target
    outputs[path].labels << {
      x: w / 2,
      y: h / 2,
      text: text.to_s,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: scale,
      r: r,
      g: g,
      b: b
    }
  end

  # returns the particle prefab
  def status_label_prefab(s_l)
    # create the rt for the particle (this will return/no-op if the RT
    # has already been created)
    path =
      create_particle_rt!(
        s_l.text,
        s_l.r,
        s_l.g,
        s_l.b,
        s_l.scale,
        s_l.w,
        s_l.h
      )

    # if the particle was created this frame, skip its render
    # since the RT won't be processed until the next tick
    if s_l.created_at == Kernel.tick_count
      nil
    else
      # return a prefab that represents the RT/label as a sprite
      {
        x: s_l.x,
        y: s_l.y,
        w: s_l.w,
        h: s_l.h,
        anchor_x: 0.5,
        anchor_y: 0.5,
        angle_anchor_x: 0.5,
        angle_anchor_y: 0.5,
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
