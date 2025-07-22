# frozen_string_literal: true

class Game
  attr_gtk
  attr :scene, :input_locked, :runs_completed, :transitioning_scenes

  def initialize
    $game = self
    @prev_sc
    @next_sc
    @scene_args
    @transitioning_scenes = false

    @autosaved = false
    @input_locked = false
    @scene = $files.save_data&.[]("scene")
    @runs_completed = $files.save_data["runs_completed"] ||= 0
    @scene_ref = nil
    @paused_scene_ref = nil
    @paused = false
    @pause_button_pos = 200 + 20
    AnimationManager.new
    AnnouncementManager.new
    EventBus.new
    @transition = nil

    # keeps track of whether an entity with a specific entity_id has been created already
    @created_entity_ids = []
    # currently list of status_labels to render to the screen at any given frame
    @status_labels = []
    # queue of labels to render to the screen
    @status_labels_queue = []
    @status_label_queue_count = Kernel.tick_count
    # keeps track of whether a render target for the specific number has been created already
    @created_prefabs = {}
    # the game's official instantiation of a Player for an individual game.
    @player = Player.new()
    # the game's official instantiation of a RecipeBook, persists between runs
    @recipe_book = RecipeBook.new()
    EncounterManager.new()

    @player.load_inventory_data
    @player.load_upgrades_data

    is_mid_run = $files.save_data&.[]("mid_run")
    encounters_completed = $files.save_data&.[]("encounters_completed")

    if is_mid_run
      change_scene(prev_sc: "", next_sc: @scene, quick: true)
    else
      new_run
    end
  end

  # reset vars for new run
  def new_run
    $files.save_data["mid_run"] = true
    $encounter_manager.reset!
    @player.reset!

    # if it is not the players first time playing
    if @runs_completed && @runs_completed > 0
      change_scene(prev_sc: "", next_sc: "map", quick: true)

      #sStart of first run for new player (scripted intro then scripted combat encounter before natural gameplay)
    else
      @input_locked = true
      change_scene(prev_sc: "", next_sc: "intro", quick: true)
    end
  end

  def change_scene(
    prev_sc:,
    next_sc:,
    args: [],
    quick: false,
    no_transition: false
  )
    @prev_sc = ""
    @next_sc = ""
    @scene_args = []

    @prev_sc = prev_sc
    @next_sc = next_sc
    @scene_args = args
    start_scene_change

    if no_transition
      finish_scene_change
    else
      if quick
        finish_scene_change
        transition_scene(start_midway: true)
      else
        transition_scene(start_midway: false)
      end
    end
  end

  def transition_scene(start_midway: false)
    @input_locked = true
    @transition = Transition.new(start_midway: start_midway)
    @transitioning_scenes = true if !@transition.start_midway
  end

  def start_scene_change()
    @scene_ref.cleanup if @prev_sc != ""
    @scene = @next_sc

    if @next_sc == "run_summary" || @next_sc == "meta_shop"
      @pause_button_pos = 15
    else
      @pause_button_pos = 200 + 15
    end
  end

  def finish_scene_change()
    $announcement_manager.clear_announcements_queue
    case @scene
    when "combat"
      @scene_ref = Combat.new(@scene_args[0])
    when "alchemy_table"
      @scene_ref = AlchemyTable.new(max_uses: $player.alchemy_table_uses)
    when "alchemy_lab"
      from_tutorial = false
      from_tutorial = @scene_args[0].values[0] if !@scene_args.empty?

      @scene_ref =
        AlchemyLab.new(
          max_uses: 10,
          max_ingredients: $player.starting_inventory_size,
          tutorial: from_tutorial
        )
    when "rewards_screen"
      @scene_ref = RewardsScreen.new(picks: $player.reward_picks)
    when "boss_rewards_screen"
      @scene_ref = BossRewardsScreen.new(boss_defeated_id: @scene_args[0])
    when "map"
      @scene_ref = Map.new()
    when "run_summary"
      @scene_ref = RunSummary.new()
    when "meta_shop"
      @scene_ref = MetaShop.new()
    when "intro"
      @scene_ref = Intro.new
    when "combat_tutorial"
      @scene_ref = CombatTutorial.new
    when "rp_encounter"
      @scene_ref = RoleplayEncounter.new
    end

    $files.save_data["scene"] = @next_sc
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

  def increment_runs_completed
    @runs_completed += 1
    $files.save_data["runs_completed"] = @runs_completed
    $files.write
  end

  def tick
    handle_pause

    if !@status_labels_queue.empty? &&
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

    if @transition
      @transition.tick
      if @transitioning_scenes && @transition.past_midway?
        finish_scene_change
        @transitioning_scenes = false
      end
      if @transition.completed
        @transition = nil
        @input_locked = false
        @scene_ref.ready if @scene_ref.respond_to?(:ready)
      end
    end

    $animation_manager.tick if $animation_manager
    $announcement_manager.tick
    render
    calc_particles

    # puts $files.save_data to file
    if (GTK.quit_requested? && !@autosaved) ||
         GTK.args.inputs.keyboard.key_down.s
      puts $files.save_data
      $files.write
      puts "WRITING SAVE DATA TO FILE"
    end
  end

  def render
    outputs = GTK.args.outputs
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
    l4 << $announcement_manager&.prefab

    # render scene pipeline layers
    outputs.primitives << [l0, l1, l2, l3, l4]

    # render pause button
    outputs.primitives << pause_btn(x: @pause_button_pos) if not @paused

    # render scene transition overlay
    outputs.primitives << @transition.prefab if @transition

    if Kernel.tick_count == 0
      # args.outputs.static_primitives << Layout.debug_primitives.map do |primitive|
      #   primitive.merge(r: 255, g: 255, b: 255)
      # end
      # args.outputs.static_primitives << Layout.debug_primitives
    end
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
