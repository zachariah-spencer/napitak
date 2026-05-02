# frozen_string_literal: true

class Game
  attr_gtk
  attr_accessor :input_locked
  attr_reader :runs_completed

  def initialize
    $GAME = self
    @input_locked = false
    @autosaved = false
    @runs_completed = 0
    @mid_run = false
    @tutorial_completed = false
    @defeat_banner_alpha = 0

    AudioService.new
    AnnouncementManager.new
    EventBus.new
    Player.new
    RecipeBook.new
    EncounterManager.new

    @scene_manager = Services::SceneManager.new(self)
    @particle_system = Services::ParticleSystem.new
    @camera_controller = Services::CameraController.new
    @hud = Ui::Hud.new(scene_manager: @scene_manager)

    initialize_save_data_vars

    if @mid_run
      change_scene(prev_sc: "", next_scene: scene, quick: true)
    else
      new_run
    end
  end

  def scene
    @scene_manager.scene
  end

  def scene_ref
    @scene_manager.scene_ref
  end

  def transitioning_scenes
    @scene_manager.transitioning?
  end

  def camera
    @camera_controller.camera_state
  end

  def initialize_save_data_vars
    @runs_completed = $files.save_data["runs_completed"] ||= 0
    @mid_run = $files.save_data&.[]("mid_run") || false
    tutorials = $files.save_data["tutorials"] || {}
    @tutorial_completed = tutorials["alchemy_lab_tutorial"] || false

    $player.load_inventory_data
    $player.load_upgrades_data

    if @mid_run
      $player.load_feathers_data
      $player.load_run_upgrades_data
    end
  end

  def new_run
    @scene_manager.toggle_pause(paused_scene_ref: @scene_manager.scene_ref) if @scene_manager.paused?
    @mid_run = true
    $files.save_data["mid_run"] = true
    $encounter_manager.reset!
    $player.reset!

    if $files.save_data["settings"].key?("replay_tutorial") &&
         $files.save_data["settings"]["replay_tutorial"]
      @input_locked = true
      change_scene(prev_sc: "", next_scene: "intro", quick: true)
      return
    end

    if (@runs_completed && @runs_completed > 0) || @tutorial_completed
      change_scene(prev_sc: "", next_scene: "map", quick: true)
    else
      @input_locked = true
      change_scene(prev_sc: "", next_scene: "intro", quick: true)
    end
  end

  def change_scene(**kwargs)
    @scene_manager.change_scene(**kwargs)
  end

  def toggle_collection(collection_scene_ref: nil, title: "", collection: [])
    @scene_manager.toggle_collection(
      collection_scene_ref: collection_scene_ref,
      title: title,
      collection: collection
    )
  end

  def increment_runs_completed
    @runs_completed += 1
    $files.save_data["runs_completed"] = @runs_completed
    $files.write
  end

  def tick
    $player.feathers += 1 if GTK.args.inputs.keyboard.key_down.m
    $AUDIO_SERVICE.tick

    @hud.tick(self)
    @camera_controller.update

    if $player.combat_stats.dead &&
         $player.combat_stats.dead_tick.elapsed_time >= 3.0.seconds && @mid_run
      end_run
    elsif $player.combat_stats.dead &&
          $player.combat_stats.dead_tick.elapsed_time < 3.0.seconds
      $GAME.input_locked = true
      @defeat_banner_alpha = @defeat_banner_alpha.lerp(255, 0.04)
    end

    @particle_system.process_queue!
    @scene_manager.calc_transitions

    if scene_ref
      scene_ref.args = args
      scene_ref.tick
    end

    $announcement_manager.tick
    render

    @particle_system.advance_particles!

    if (GTK.quit_requested? && !@autosaved) ||
         GTK.args.inputs.keyboard.key_down.s
      puts $files.save_data
      $files.write
      puts "WRITING SAVE DATA TO FILE"
    end
  end

  def render
    outputs = GTK.args.outputs
    l00 = []
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []
    l5 = []

    background_solid = {
      x: -1024,
      y: -1024,
      w: 1280 + 1024,
      h: 720 + 1024,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    }

    l00 << background_solid

    if scene_ref
      l0 << scene_ref.render(0)
      l1 << scene_ref.render(1)
      l2 << scene_ref.render(2)
      l3 << scene_ref.render(3)
      l4 << scene_ref.render(4)
      sub_transitions = scene_ref.render(5)
    end

    @particle_system.sparkle_prefabs.each { |prefab| l4 << prefab }
    @particle_system.status_label_prefabs.each { |prefab| l4 << prefab }

    if $player.combat_stats.dead_tick && @mid_run
      banner_f_i =
        Numeric.frame_index(start_at: 0, count: 18, hold_for: 6, repeat: true)
      defeat_banner_label = {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2,
        alignment_enum: 1,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: 50,
        r: 255,
        g: 255,
        b: 255,
        a: @defeat_banner_alpha,
        font: $FONT,
        text: "DEFEAT",
        primitive_marker: :label
      }

      defeat_banner = {
        path: "sprites/combat_banner_frames/combat_banner#{banner_f_i + 1}.png",
        x: 0,
        y: GTK.args.grid.h / 2 - 64,
        w: 1280,
        h: 128,
        r: 255,
        g: 0,
        b: 0,
        a: @defeat_banner_alpha,
        primitive_marker: :sprite
      }

      l4 << [defeat_banner, defeat_banner_label]
    end

    @hud.layer_primitives.each { |primitive| l5 << primitive }

    if GTK.platform?(:web) && Kernel.tick_count < 5.3.seconds
      l5 << web_performance_warning_prefab
    end

    l5 << $announcement_manager&.prefab
    l5 << @scene_manager.transition.prefab if @scene_manager.transition

    all_render_layers = [l0, l1, l2, l3, l4, l5]
    all_render_layers.each_with_index do |layer, idx|
      next if layer.nil? || layer.empty?

      apply_world = idx < 5
      apply_shake = apply_world || @camera_controller.shake_includes_ui?

      @camera_controller.apply_to_renderables!(
        layer,
        apply_world_transform: apply_world,
        apply_shake: apply_shake
      )
    end

    outputs.primitives << l00
    outputs.primitives << all_render_layers
    outputs.primitives << sub_transitions if sub_transitions
  end

  def camera_shake(intensity: 8.0, duration: 0.3.seconds, include_ui: false)
    @camera_controller.shake(
      intensity: intensity,
      duration: duration,
      include_ui: include_ui
    )
  end

  def end_run
    @mid_run = false
    $files.save_data["mid_run"] = false
    $player.anodyne += $encounter_manager.calc_anodyne_earnings
    $player.save_upgrades_data
    change_scene(prev_sc: scene_ref&.sc_id, next_scene: "run_summary")
  end

  def status_label(x, y, text, r, g, b, scale)
    @particle_system.queue_status_label(x, y, text, r, g, b, scale)
  end

  def sparkle_particle(x:, y:, r:, g:, b:)
    @particle_system.spawn_sparkle(x: x, y: y, r: r, g: g, b: b)
  end

  def reset_scene_particles!
    @particle_system.reset_scene_particles!
  end

  def on_scene_loaded(_scene)
    # hook for future orchestration needs
  end

  def web_performance_warning_prefab
    [
      {
        x: 640,
        y: 380,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
        size_px: 22,
        text: "Note! This is the web build! It will run slowly!",
        font: $FONT,
        r: 255,
        g: 255,
        b: 255,
        a: (Math.sin(Kernel.tick_count / 30.0) * 0.5 + 0.5) * 255,
        primitive_marker: :label
      },
      {
        x: 640,
        y: 340,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
        size_px: 22,
        text:
          "For better performance, please try the compatible Windows/Mac/Linux build!",
        font: $FONT,
        r: 255,
        g: 255,
        b: 255,
        a: (Math.sin(Kernel.tick_count / 30.0) * 0.5 + 0.5) * 255,
        primitive_marker: :label
      }
    ]
  end
end
