# frozen_string_literal: true

module Services
  class SceneManager
    attr_reader :scene, :scene_ref, :transition

    def initialize(game)
      @game = game
      reset_state
    end

    def reset_state
      @prev_sc = nil
      @next_sc = nil
      @next_scene_instance = nil
      @scene_args = []
      @scene = $files.save_data&.[]("scene")
      @transition = nil
      @transitioning_scenes = false
      @scene_ref = nil
      @collection_scene_ref = nil
      @viewing_collection = false
      @paused_scene_ref = nil
      @paused_music_sym = nil
      @paused = false
    end

    def transitioning?
      @transitioning_scenes
    end

    def paused?
      @paused
    end

    def viewing_collection?
      @viewing_collection
    end

    def change_scene(prev_sc:, next_scene:, args: [], quick: false, no_transition: false)
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

    def toggle_pause(paused_scene_ref: nil)
      @paused = !@paused

      if @paused
        @scene = "pause_menu"
        @paused_scene_ref = paused_scene_ref if paused_scene_ref
        @paused_music_sym = $AUDIO_SERVICE.current_song
        @scene_ref = PauseMenu.new
      else
        @scene = @paused_scene_ref.sc_id
        @scene_ref.cleanup if @scene_ref.respond_to?(:cleanup)
        $AUDIO_SERVICE.play_song(@paused_music_sym) if @paused_music_sym
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
        @scene_ref.cleanup if @scene_ref.respond_to?(:cleanup)
        @scene_ref = @collection_scene_ref
      end
    end

    def calc_transitions
      return unless @transition

      @transition.tick
      if @transitioning_scenes && @transition.past_midway?
        finish_scene_change
        @transitioning_scenes = false
      end
      if @transition.completed
        @transition = nil
        @game.input_locked = false
        @scene_ref.ready if @scene_ref.respond_to?(:ready)
      end
    end

    private

    def start_scene_change
      @scene_ref.cleanup if @prev_sc != "" && @scene_ref && @scene_ref.respond_to?(:cleanup)
      @scene = @next_sc
    end

    def transition_scene(start_midway: false)
      @game.input_locked = true
      @transition = Transition.new(start_midway: start_midway)
      @transitioning_scenes = !@transition.start_midway
    end

    def finish_scene_change
      $announcement_manager.clear_announcements_queue
      @game.reset_scene_particles!

      if @next_scene_instance
        @scene_ref = @next_scene_instance
        @next_scene_instance = nil
      else
        @scene_ref = instantiate_scene(@scene, @scene_args)
      end

      $files.save_data["scene"] = @next_sc
      @game.on_scene_loaded(@scene_ref)
    end

    def instantiate_scene(scene_id, args)
      case scene_id
      when "combat"
        Combat.new(args[0])
      when "alchemy_table"
        AlchemyTable.new(max_uses: $player.alchemy_table_uses)
      when "alchemy_lab"
        first_arg = args.first
        from_tutorial =
          if first_arg && first_arg.respond_to?(:values)
            first_arg.values[0]
          else
            false
          end
        AlchemyLab.new(
          max_uses: 10,
          max_ingredients: $player.starting_inventory_size,
          tutorial: from_tutorial
        )
      when "rewards_screen"
        RewardsScreen.new(picks: $player.reward_picks)
      when "boss_rewards_screen"
        BossRewardsScreen.new(boss_defeated_id: args[0])
      when "map"
        Map.new
      when "run_summary"
        RunSummary.new
      when "meta_shop"
        MetaShop.new
      when "intro"
        Intro.new
      when "combat_tutorial"
        CombatTutorial.new
      when "rp_encounter"
        RoleplayEncounter.new
      when "shop"
        Shop.new
      else
        nil
      end
    end
  end
end


