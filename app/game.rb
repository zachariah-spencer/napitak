# frozen_string_literal: true

class Game
  attr_gtk
  attr :scene, :input_locked, :runs_completed, :transitioning_scenes

  def initialize
    $game = self
    @prev_sc
    @next_sc
    @next_scene_instance
    @scene_args
    @transitioning_scenes = false
    @defeat_banner_alpha = 0
    @autosaved = false
    @input_locked = false
    @scene = $files.save_data&.[]("scene")
    @runs_completed = $files.save_data["runs_completed"] ||= 0
    @scene_ref = nil
    @collection_scene_ref = nil
    @viewing_collection = false
    @pause_btn =
      Button.new(
        x: 128 + 16 + 8,
        y: GTK.args.grid.h - 32,
        w: 32,
        h: 32,
        path: "sprites/pause_button-sheet-4.png",
        tile_rect: {
          x: 32,
          y: 0,
          w: 32,
          h: 32
        },
        frame_length: 4,
        text: ""
      )
    @paused_scene_ref = nil
    @paused_music_sym = nil
    @paused = false
    @status_effect_list_widget =
      StatusEffectListWidget.new(
        x: misc_btn[:x] - 128 + 16,
        y: GTK.args.grid.h - 64,
        hover_rect: misc_btn
      )
    @pot_col_btn = {
      x: GTK.args.grid.w / 2 - 16 + 200,
      y: GTK.args.grid.h - 32,
      w: 32,
      h: 32,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: "sprites/bottle.png"
    }
    @ing_col_btn = {
      x: GTK.args.grid.w / 2 - 16 - 175,
      y: GTK.args.grid.h - 32,
      w: 32,
      h: 32,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: "sprites/fire.png"
    }
    @pot_btn_label = {
      x: GTK.args.grid.w / 2 - 16 + 200,
      y: GTK.args.grid.h - 80,
      anchor_x: 0.5,
      anchor_y: 0.5,
      font: $FONT,
      text: "Potions",
      size_px: 18,
      r: 255,
      g: 255,
      b: 255,
      a: 255
    }
    @ing_btn_label = {
      x: GTK.args.grid.w / 2 - 16 - 175,
      y: GTK.args.grid.h - 80,
      anchor_x: 0.5,
      anchor_y: 0.5,
      font: $FONT,
      text: "Ingredients",
      size_px: 18,
      r: 255,
      g: 255,
      b: 255,
      a: 255
    }
    AudioService.new
    # AnimationService.new
    # AnimationManager.new
    AnnouncementManager.new
    EventBus.new

    @transition = nil
    @mid_run = $files.save_data&.[]("mid_run") || false

    # keeps track of whether an entity with a specific entity_id has been created already
    @created_entity_ids = []
    # currently list of status_labels to render to the screen at any given frame
    @status_labels = []
    @sparkle_particles = []
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

    @tutorial_completed =
      $files.save_data["tutorials"]["alchemy_lab_tutorial"] ||
        false if $files.save_data["tutorials"]["alchemy_lab_tutorial"]

    @player.load_inventory_data
    @player.load_upgrades_data
    encounters_completed = $files.save_data&.[]("encounters_completed")

    # camera state
    @camera = { x: 0.0, y: 0.0, zoom: 1.0 }
    @cam_shake_active = false
    @cam_shake_amp = 0.0
    @cam_shake_end_tick = 0
    @cam_shake_include_ui = false
    @cam_shake_offset_x = 0.0
    @cam_shake_offset_y = 0.0

    @hp_shard_label_a = 0
    @hp_shard_label_da = 0
    @focus_shard_label_a = 0
    @focus_shard_label_da = 0

    if @mid_run
      @player.load_feathers_data
      @player.load_run_upgrades_data
      change_scene(prev_sc: "", next_scene: @scene, quick: true)
    else
      new_run
    end
  end

  # reset vars for new run
  def new_run
    @paused = false
    @mid_run = true
    $files.save_data["mid_run"] = true
    $encounter_manager.reset!
    @player.reset!

    if $files.save_data["settings"].key?("replay_tutorial") &&
         $files.save_data["settings"]["replay_tutorial"]
      @input_locked = true
      change_scene(prev_sc: "", next_scene: "intro", quick: true)
      return
    end

    # if it is not the players first time playing
    if @runs_completed && @runs_completed > 0 || @tutorial_completed
      change_scene(prev_sc: "", next_scene: "map", quick: true)

      #Start of first run for new player (scripted intro then scripted combat encounter before natural gameplay)
    else
      @input_locked = true
      change_scene(prev_sc: "", next_scene: "intro", quick: true)
    end
  end

  def change_scene(
    prev_sc:,
    next_scene:,
    args: [],
    quick: false,
    no_transition: false
  )
    @prev_sc = ""
    @next_sc = ""
    @scene_args = []
    @next_scene_instance = nil

    @prev_sc = prev_sc.is_a?(Scene) ? prev_sc.sc_id : prev_sc
    if next_scene.is_a?(Scene)
      @next_scene_instance = next_scene
      @next_sc = next_scene.sc_id
    else
      @next_sc = next_scene
    end
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
  end

  def finish_scene_change()
    $announcement_manager.clear_announcements_queue
    @sparkle_particles.clear
    if @next_scene_instance
      @scene_ref = @next_scene_instance
      @next_scene_instance = nil
    else
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
      when "shop"
        @scene_ref = Shop.new
      end
    end

    $files.save_data["scene"] = @next_sc
  end

  def toggle_pause(paused_scene_ref: nil)
    @paused = !@paused

    if @paused
      @scene = "pause_menu"
      @paused_scene_ref = paused_scene_ref if paused_scene_ref
      @paused_music_sym = $AUDIO_SERVICE.current_song
      @scene_ref = PauseMenu.new
    else
      @scene = @paused_scene_ref.sc_id
      @scene_ref.cleanup
      $AUDIO_SERVICE.play_song(@paused_music_sym)
      @scene_ref = @paused_scene_ref
    end
  end

  def toggle_collection(collection_scene_ref: nil, title: "", collection: [])
    @viewing_collection = !@viewing_collection

    if @viewing_collection
      $AUDIO_SERVICE.play_sound(:open_book)
      @scene = "collection"
      @collection_scene_ref = collection_scene_ref if collection_scene_ref
      @scene_ref = Collection.new(title: title, collection_array: collection)
    else
      $AUDIO_SERVICE.play_sound(:close_book)
      @scene = @collection_scene_ref.sc_id
      @scene_ref.cleanup
      @scene_ref = @collection_scene_ref
    end
  end

  def handle_pause
    @pause_btn.tick
    if (
         GTK.args.inputs.keyboard.key_down.escape &&
           @scene_ref.sc_id != "collection"
       ) || (@pause_btn.clicked? && @scene_ref.sc_id != "collection")
      toggle_pause(paused_scene_ref: @scene_ref)
    end
  end

  def increment_runs_completed
    @runs_completed += 1
    $files.save_data["runs_completed"] = @runs_completed
    $files.write
  end

  def calc_transitions
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
  end

  def tick
    $player.feathers += 1 if GTK.args.inputs.keyboard.key_down.m
    $AUDIO_SERVICE.tick
    handle_pause
    calc_view_collection_inputs
    calc_button_inputs
    @status_effect_list_widget.tick
    update_camera_shake

    if $player.combat_stats.dead &&
         $player.combat_stats.dead_tick.elapsed_time >= 3.0.seconds && @mid_run
      end_run
    elsif $player.combat_stats.dead &&
          $player.combat_stats.dead_tick.elapsed_time < 3.0.seconds
      $game.input_locked = true
      @defeat_banner_alpha = @defeat_banner_alpha.lerp(255, 0.04)
    end

    if !@status_labels_queue.empty? &&
         @status_label_queue_count.elapsed_time >= 0.2.seconds
      new_label = @status_labels_queue.shift
      new_label.created_at = Kernel.tick_count
      @status_label_queue_count = Kernel.tick_count
      @status_labels << new_label
      @new_status_label_queued = false
    end

    calc_transitions

    if @scene_ref
      @scene_ref.args = args
      @scene_ref.tick
    end
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

  def calc_view_collection_inputs()
    if !@paused && !$game.input_locked
      if GTK.args.inputs.keyboard.key_down.tab ||
           GTK.args.inputs.mouse.click &&
             GTK.args.inputs.mouse.intersect_rect?(@ing_col_btn) &&
             !@viewing_collection
        ing_ids = []
        $player.ingredients.all_cards.each { |c| ing_ids << c.id }
        toggle_collection(
          collection_scene_ref: @scene_ref,
          title: "Ingredients",
          collection: $player.ingredients.all_cards
        )
      elsif GTK.args.inputs.keyboard.key_down.shift_left ||
            GTK.args.inputs.mouse.click &&
              GTK.args.inputs.mouse.intersect_rect?(@pot_col_btn) &&
              !@viewing_collection
        pot_ids = []
        $player.potions.all_cards.each { |c| pot_ids << c.id }
        if @scene_ref.sc_id == "combat" || @scene_ref.sc_id == "combat_tutorial"
          @scene_ref.hand_manager.hand.each { |id, c| pot_ids << c.id }
        end
        toggle_collection(
          collection_scene_ref: @scene_ref,
          title: "Potions",
          collection: $player.potions.all_cards
        )
      end
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

    if @scene_ref
      # l0.flatten!
      # l1.flatten!
      # l2.flatten!
      # l3.flatten!
      # l4.flatten!
      l0 << @scene_ref.render(0)
      l1 << @scene_ref.render(1)
      l2 << @scene_ref.render(2)
      l3 << @scene_ref.render(3)
      l4 << @scene_ref.render(4)
    end

    # for each particle, construct a prefab
    @sparkle_particles.each { |particle| l4 << particle.prefab }
    l4 << @status_labels.map { |particle| status_label_prefab particle }

    if $player.combat_stats.dead_tick && @mid_run
      banner_f_i =
        Numeric.frame_index(start_at: 0, count: 18, hold_for: 6, repeat: true)
      defeat_banner_label ||= {
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

    # render pause button
    l5 << @pause_btn.prefab if @scene_ref.sc_id != "collection"
    if !@viewing_collection && !@paused
      l5 << [
        @pot_btn_label,
        @pot_col_btn,
        @ing_btn_label,
        @ing_col_btn,
        hp_label[:icon],
        hp_label[:label],
        focus_label[:icon],
        focus_label[:label]
      ]
      if !$player.status_effects.empty?
        l5 << [
          misc_btn,
          @status_effect_list_widget.prefab[:background],
          @status_effect_list_widget.prefab[:label],
          @status_effect_list_widget.prefab[:list]
        ]
      end
      @hp_shard_label_da = ($player.hp_shards > 0) ? 180 : 0
      @hp_shard_label_a = @hp_shard_label_a.lerp(@hp_shard_label_da, 0.2)
      @focus_shard_label_da = ($player.focus_shards > 0) ? 180 : 0
      @focus_shard_label_a = @focus_shard_label_a.lerp(@focus_shard_label_da, 0.2)

      l5 << hp_shards_label
      l5 << focus_shards_label
    end

    feathers_icon_fi = Numeric.frame_index(
      start_at: 0,
      hold_for: 10,
      count: 4,
      repeat: true
    )
    feathers_icon = {
      x: GTK.args.grid.w / 2,
      anchor_x: 0.5,
      y: GTK.args.grid.h - 32 - 16,
      w: 32,
      h: 32,
      a: 255,
      path: "sprites/feathers_icon-sheet-128x128-4.png",
      tile_x: 128 * feathers_icon_fi,
      tile_w: 128,
      tile_h: 128,
      primitive_marker: :sprite
    }

    feathers_amount = {
      x: GTK.args.grid.w / 2,
      anchor_x: 0.5,
      y: GTK.args.grid.h - 32,
      size_px: 18,
      anchor_y: 0.5,
      text: "#{$player.feathers}",
      r: 255,
      g: 255,
      b: 255,
      font: $FONT,
      primitive_marker: :label
    }

    encounters_amount = {
      x: 128 + 80,
      anchor_x: 0.5,
      y: GTK.args.grid.h - 32,
      size_px: 22,
      anchor_y: 0.5,
      text: "-#{$encounter_manager.encounters_completed}-",
      r: 255,
      g: 255,
      b: 255,
      font: $FONT,
      primitive_marker: :label
    }

    l5 << [feathers_icon, feathers_amount, encounters_amount]

    l5 << $announcement_manager&.prefab
    # render scene transition overlay
    l5 << @transition.prefab if @transition

    # render scene pipeline layers
    all_render_layers = [l0, l1, l2, l3, l4, l5]
    all_render_layers.each_with_index do |layer, idx|
      next if layer.nil? || layer.empty?
      apply_world = idx < 5 # world layers (UI is layer 5)
      apply_shake = apply_world || @cam_shake_include_ui
      apply_camera_transform_to_renderables!(
        layer,
        apply_world_transform: apply_world,
        apply_shake: apply_shake
      )
    end
    outputs.primitives << l00
    outputs.primitives << all_render_layers
  end

  # Camera/shake control
  def camera_shake(intensity: 8.0, duration: 0.3.seconds, include_ui: false)
    @cam_shake_active = true
    @cam_shake_amp = intensity.to_f
    @cam_shake_start_tick = Kernel.tick_count
    @cam_shake_end_tick = Kernel.tick_count + duration.to_i
    @cam_shake_include_ui = include_ui
  end

  def update_camera_shake
    if @cam_shake_active
      if Kernel.tick_count >= @cam_shake_end_tick
        @cam_shake_active = false
        @cam_shake_offset_x = 0.0
        @cam_shake_offset_y = 0.0
      else
        total = (@cam_shake_end_tick - @cam_shake_start_tick).to_f
        elapsed = (Kernel.tick_count - @cam_shake_start_tick).to_f
        t = (elapsed / total).clamp(0.0, 1.0)
        falloff = 1.0 - t # linear falloff
        amp = @cam_shake_amp * falloff
        @cam_shake_offset_x = Numeric.rand(-amp..amp)
        @cam_shake_offset_y = Numeric.rand(-amp..amp)
      end
    else
      @cam_shake_offset_x = 0.0
      @cam_shake_offset_y = 0.0
    end
  end

  def apply_camera_transform_to_renderables!(
    renderables,
    apply_world_transform:,
    apply_shake: true
  )
    return if renderables.nil?
    renderables.map! do |r|
      if r.is_a?(Array)
        apply_camera_transform_to_renderables!(
          r,
          apply_world_transform: apply_world_transform,
          apply_shake: apply_shake
        )
        r
      elsif r.is_a?(Hash)
        apply_camera_transform_to_hash!(
          r,
          apply_world_transform: apply_world_transform,
          apply_shake: apply_shake
        )
      else
        r
      end
    end
  end

  def apply_camera_transform_to_hash!(
    h,
    apply_world_transform:,
    apply_shake: true
  )
    return h if h.nil?
    ox = 0.0
    oy = 0.0
    if apply_world_transform
      ox -= @camera[:x].to_f
      oy -= @camera[:y].to_f
    end
    if apply_shake
      ox += @cam_shake_offset_x
      oy += @cam_shake_offset_y
    end

    h[:x] = h[:x].to_f + ox if h.key?(:x)
    h[:y] = h[:y].to_f + oy if h.key?(:y)
    h[:x1] = h[:x1].to_f + ox if h.key?(:x1)
    h[:y1] = h[:y1].to_f + oy if h.key?(:y1)
    h[:x2] = h[:x2].to_f + ox if h.key?(:x2)
    h[:y2] = h[:y2].to_f + oy if h.key?(:y2)
    h
  end

  def calc_button_inputs
    pot_hovered = GTK.args.inputs.mouse.intersect_rect?(@pot_col_btn)
    if pot_hovered
      @pot_col_btn[:w] = @pot_col_btn[:w].lerp(64, 0.2)
      @pot_col_btn[:h] = @pot_col_btn[:h].lerp(64, 0.2)
      @pot_btn_label[:a] = @pot_btn_label[:a].lerp(255, 0.2)
    else
      @pot_col_btn[:w] = @pot_col_btn[:w].lerp(32, 0.2)
      @pot_col_btn[:h] = @pot_col_btn[:h].lerp(32, 0.2)
      @pot_btn_label[:a] = @pot_btn_label[:a].lerp(0, 0.2)
    end

    ing_hovered = GTK.args.inputs.mouse.intersect_rect?(@ing_col_btn)
    if ing_hovered
      @ing_col_btn[:w] = @ing_col_btn[:w].lerp(64, 0.2)
      @ing_col_btn[:h] = @ing_col_btn[:h].lerp(64, 0.2)
      @ing_btn_label[:a] = @ing_btn_label[:a].lerp(255, 0.2)
    else
      @ing_col_btn[:w] = @ing_col_btn[:w].lerp(32, 0.2)
      @ing_col_btn[:h] = @ing_col_btn[:h].lerp(32, 0.2)
      @ing_btn_label[:a] = @ing_btn_label[:a].lerp(0, 0.2)
    end
  end

  def misc_btn
    f_i = 0.frame_index(count: 4, hold_for: 15, repeat: true)
    {
      x: GTK.args.grid.w - 128 - 32 - 16,
      y: GTK.args.grid.h - 16 - 32,
      w: 32,
      h: 32,
      path: "sprites/misc_button-sheet-4.png",
      tile_x: 32 * f_i,
      tile_y: 0,
      tile_w: 32,
      tile_h: 32,
      angle: 0,
      primitive_marker: :sprite
    }
  end
  def pause_btn
    f_i = 0.frame_index(count: 4, hold_for: 15, repeat: true)
    {
      x: 128 + 16,
      y: GTK.args.grid.h - 16 - 32,
      w: 32,
      h: 32,
      path: "sprites/pause_button-sheet-4.png",
      tile_x: 32 * f_i,
      tile_y: 0,
      tile_w: 32,
      tile_h: 32,
      angle: 0,
      primitive_marker: :sprite
    }
  end

  def hp_shards_label
    {
      x: GTK.args.grid.w / 2 - 32 - 80 + 16 - 32,
      y: GTK.args.grid.h - 20,
      size_px: 18,
      font: $FONT,
      text: "+#{$player.hp_shards}/3",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 0,
      b: 255,
      a: @hp_shard_label_a,
      primitive_marker: :label
    }
  end

  def hp_label
    f_i = 0.frame_index(count: 4, hold_for: 15, repeat: true)
    icon = {
      x: GTK.args.grid.w / 2 - 32 - 96 + 16,
      y: GTK.args.grid.h - 16 - 32,
      w: 32,
      h: 32,
      path: "sprites/hp_icon-sheet-4.png",
      tile_x: 32 * f_i,
      tile_y: 0,
      tile_w: 32,
      tile_h: 32,
      a: 200,
      angle: 0,
      primitive_marker: :sprite
    }

    label = {
      x: GTK.args.grid.w / 2 - 32 - 80 + 16,
      y: GTK.args.grid.h - 32,
      size_px: 18,
      font: $FONT,
      text:
        (
          if @scene_ref.sc_id == "combat" ||
               @scene_ref.sc_id == "combat_tutorial"
            "#{$player.combat_stats.hp} / #{$player.maximum_hp}"
          else
            "#{$player.maximum_hp}"
          end
        ),
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      primitive_marker: :label
    }

    { icon: icon, label: label }
  end

  def focus_shards_label
    {
      x: GTK.args.grid.w / 2 + 32 + 48 + 16 - 32,
      y: GTK.args.grid.h - 20,
      size_px: 18,
      font: $FONT,
      text: "+#{$player.focus_shards}/3",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 0,
      b: 255,
      a: @focus_shard_label_a,
      primitive_marker: :label
    }
  end

  def focus_label
    f_i = 0.frame_index(count: 4, hold_for: 15, repeat: true)
    icon = {
      x: GTK.args.grid.w / 2 - 32 + 96 + 16,
      y: GTK.args.grid.h - 16 - 32,
      w: 32,
      h: 32,
      path: "sprites/focus_icon-sheet-4.png",
      tile_x: 32 * f_i,
      tile_y: 0,
      tile_w: 32,
      tile_h: 32,
      a: 255,
      angle: 0,
      primitive_marker: :sprite
    }

    label = {
      x: GTK.args.grid.w / 2 + 32 + 48 + 16,
      y: GTK.args.grid.h - 32,
      size_px: 18,
      font: $FONT,
      text:
        (
          if @scene_ref.sc_id == "combat" ||
               @scene_ref.sc_id == "combat_tutorial"
            "#{$player.combat_stats.focus} / #{$player.combat_stats.max_focus}"
          else
            "#{$player.maximum_focus}"
          end
        ),
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      primitive_marker: :label
    }

    { icon: icon, label: label }
  end

  def end_run
    @mid_run = false
    $files.save_data["mid_run"] = false
    $player.anodyne += $encounter_manager.calc_anodyne_earnings
    $player.save_upgrades_data
    $game.change_scene(prev_sc: @sc_id, next_scene: "run_summary")
  end

  def calc_particles
    # process each particle setting their alpha
    # make them spin, and set their y value
    @status_labels.each do |particle|
      particle.a -= 4
      particle.angle += particle.angle_mod # / (particle.scale * 0.2)
      particle.y += 1.5
    end

    @sparkle_particles.each { |particle| particle.tick }

    # reject all particles with an alpha less than equal to 0
    @status_labels.reject! { |particle| particle.a <= 0 }
    @sparkle_particles.reject! { |particle| particle.color[:a] <= 0 }
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
      font: $FONT,
      angle_anchor_x: 0.5,
      angle_anchor_y: 0.5,
      angle_mod: Numeric.rand(-0.2..0.2)
    }
  end

  def sparkle_particle(x:, y:, r:, g:, b:)
    @sparkle_particles << SparkleParticle.new(x: x, y: y, r: r, g: g, b: b)
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
      font: $FONT,
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
        font: $FONT,
        angle: s_l.angle
      }
    end
  end
end
