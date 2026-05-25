# frozen_string_literal: true

module Ui
  class Hud
    UI_TOP_MARGIN = 32
    PAUSE_BUTTON_SIZE = 32
    COLLECTION_BUTTON_SIZE = 32
    HOVERED_COLLECTION_BUTTON_SIZE = 64
    HOVER_LERP_SPEED = 0.2
    COLLECTION_LABEL_VISIBLE_ALPHA = 255
    COLLECTION_LABEL_HIDDEN_ALPHA = 0
    COLLECTION_LABEL_FONT_SIZE = 18
    COLLECTION_LABEL_Y_OFFSET = 80

    def initialize(scene_manager:)
      @scene_manager = scene_manager
      initialize_widgets
    end

    def tick(game)
      @pause_btn.tick if @pause_btn
      handle_pause_input
      handle_collection_inputs(game)
      animate_collection_buttons
      @status_effect_list_widget.tick
      update_shard_labels
    end

    def layer_primitives
      primitives = []
      scene_ref = @scene_manager.scene_ref

      primitives << @pause_btn.prefab if scene_ref && scene_ref.sc_id != "collection" && scene_ref.sc_id != "intro"

      return primitives if @scene_manager.viewing_collection? || @scene_manager.paused?

      hp_ui = hp_label(scene_ref)
      focus_ui = focus_label(scene_ref)

      primitives << [
        @pot_btn_label,
        @pot_col_btn,
        @ing_btn_label,
        @ing_col_btn,
        hp_ui[:icon],
        hp_ui[:label],
        focus_ui[:icon],
        focus_ui[:label]
      ]

      unless $player.status_effects.empty?
        widget_prefab = @status_effect_list_widget.prefab
        primitives << [
          misc_btn,
          widget_prefab[:background],
          widget_prefab[:label],
          widget_prefab[:list]
        ]
      end

      primitives << hp_shards_label
      primitives << focus_shards_label
      primitives << feathers_hud

      primitives
    end

    private

    def initialize_widgets
      @hp_shard_label_a = 0
      @hp_shard_label_da = 0
      @focus_shard_label_a = 0
      @focus_shard_label_da = 0

      @pause_btn =
        Button.new(
          x: 128 + 16 + 8,
          y: GTK.args.grid.h - UI_TOP_MARGIN,
          w: PAUSE_BUTTON_SIZE,
          h: PAUSE_BUTTON_SIZE,
          path: "sprites/pause_button_sheet_128x128_4.png",
          tile_rect: {
            x: PAUSE_BUTTON_SIZE * 4,
            y: 0,
            w: PAUSE_BUTTON_SIZE * 4,
            h: PAUSE_BUTTON_SIZE * 4
          },
          frame_length: 4,
          text: ""
        )

      hover_rect = base_misc_button_rect
      @status_effect_list_widget =
        StatusEffectListWidget.new(
          x: hover_rect[:x] - 128 + 16,
          y: GTK.args.grid.h - 64,
          hover_rect: hover_rect
        )

      @pot_col_btn = {
        x: GTK.args.grid.w / 2 - 16 + 200,
        y: GTK.args.grid.h - UI_TOP_MARGIN,
        w: COLLECTION_BUTTON_SIZE,
        h: COLLECTION_BUTTON_SIZE,
        anchor_x: 0.5,
        anchor_y: 0.5,
        path: "sprites/bottle.png"
      }
      @ing_col_btn = {
        x: GTK.args.grid.w / 2 - 16 - 175,
        y: GTK.args.grid.h - UI_TOP_MARGIN,
        w: COLLECTION_BUTTON_SIZE,
        h: COLLECTION_BUTTON_SIZE,
        anchor_x: 0.5,
        anchor_y: 0.5,
        path: "sprites/fire.png"
      }
      @pot_btn_label = {
        x: GTK.args.grid.w / 2 - 16 + 200,
        y: GTK.args.grid.h - COLLECTION_LABEL_Y_OFFSET,
        anchor_x: 0.5,
        anchor_y: 0.5,
        font: $FONT,
        text: "Potions",
        size_px: COLLECTION_LABEL_FONT_SIZE,
        r: 255,
        g: 255,
        b: 255,
        a: COLLECTION_LABEL_VISIBLE_ALPHA
      }
      @ing_btn_label = {
        x: GTK.args.grid.w / 2 - 16 - 175,
        y: GTK.args.grid.h - COLLECTION_LABEL_Y_OFFSET,
        anchor_x: 0.5,
        anchor_y: 0.5,
        font: $FONT,
        text: "Ingredients",
        size_px: COLLECTION_LABEL_FONT_SIZE,
        r: 255,
        g: 255,
        b: 255,
        a: COLLECTION_LABEL_VISIBLE_ALPHA
      }
    end

    def handle_pause_input
      scene_ref = @scene_manager.scene_ref
      return unless scene_ref
      return if scene_ref.sc_id == "collection" || scene_ref.sc_id == "intro"

      if GTK.args.inputs.keyboard.key_down.escape || @pause_btn.clicked?
        @scene_manager.toggle_pause(paused_scene_ref: scene_ref)
      end
    end

    def handle_collection_inputs(game)
      return if @scene_manager.paused?
      return if @scene_manager.viewing_collection?
      return if game.input_locked

      scene_ref = @scene_manager.scene_ref
      return unless scene_ref

      if GTK.args.inputs.keyboard.key_down.tab || (
           GTK.args.inputs.mouse.click &&
             GTK.args.inputs.mouse.intersect_rect?(@ing_col_btn)
         )
        toggle_collection(
          scene_ref: scene_ref,
          title: "Ingredients",
          collection: $player.ingredients.all_cards
        )
      elsif GTK.args.inputs.keyboard.key_down.shift_left || (
              GTK.args.inputs.mouse.click &&
                GTK.args.inputs.mouse.intersect_rect?(@pot_col_btn)
            )
        toggle_collection(
          scene_ref: scene_ref,
          title: "Potions",
          collection: $player.potions.all_cards
        )
      end
    end

    def toggle_collection(scene_ref:, title:, collection:)
      @scene_manager.toggle_collection(
        collection_scene_ref: scene_ref,
        title: title,
        collection: collection
      )
    end

    def animate_collection_buttons
      animate_hover!(@pot_col_btn, @pot_btn_label)
      animate_hover!(@ing_col_btn, @ing_btn_label)
    end

    def animate_hover!(button_hash, label_hash)
      hovered = GTK.args.inputs.mouse.intersect_rect?(button_hash)
      target_size = hovered ? HOVERED_COLLECTION_BUTTON_SIZE : COLLECTION_BUTTON_SIZE
      target_alpha =
        hovered ? COLLECTION_LABEL_VISIBLE_ALPHA : COLLECTION_LABEL_HIDDEN_ALPHA

      button_hash[:w] = button_hash[:w].lerp(target_size, HOVER_LERP_SPEED)
      button_hash[:h] = button_hash[:h].lerp(target_size, HOVER_LERP_SPEED)
      label_hash[:a] = label_hash[:a].lerp(target_alpha, HOVER_LERP_SPEED)
    end

    def update_shard_labels
      @hp_shard_label_da = ($player.hp_shards > 0) ? 180 : 0
      @hp_shard_label_a = @hp_shard_label_a.lerp(@hp_shard_label_da, 0.2)
      @focus_shard_label_da = ($player.focus_shards > 0) ? 180 : 0
      @focus_shard_label_a =
        @focus_shard_label_a.lerp(@focus_shard_label_da, 0.2)
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

    def hp_label(scene_ref)
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

      label_text = if scene_ref && %w[combat combat_tutorial].include?(scene_ref.sc_id)
                     "#{$player.combat_stats.hp} / #{$player.maximum_hp}"
                   else
                     "#{$player.maximum_hp}"
                   end

      label = {
        x: GTK.args.grid.w / 2 - 32 - 80 + 16,
        y: GTK.args.grid.h - 32,
        size_px: 18,
        font: $FONT,
        text: label_text,
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255,
        primitive_marker: :label
      }

      { icon: icon, label: label }
    end

    def focus_label(scene_ref)
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

      label_text = if scene_ref && %w[combat combat_tutorial].include?(scene_ref.sc_id)
                     "#{$player.combat_stats.focus} / #{$player.combat_stats.max_focus}"
                   else
                     "#{$player.maximum_focus}"
                   end

      label = {
        x: GTK.args.grid.w / 2 + 32 + 48 + 16,
        y: GTK.args.grid.h - 32,
        size_px: 18,
        font: $FONT,
        text: label_text,
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255,
        primitive_marker: :label
      }

      { icon: icon, label: label }
    end

    def feathers_hud
      [feathers_icon, feathers_amount, encounters_amount]
    end

    def feathers_icon
      f_i = Numeric.frame_index(start_at: 0, hold_for: 10, count: 4, repeat: true)
      {
        x: GTK.args.grid.w / 2,
        anchor_x: 0.5,
        y: GTK.args.grid.h - 32 - 16,
        w: 32,
        h: 32,
        a: 255,
        path: "sprites/feathers_icon-sheet-128x128-4.png",
        tile_x: 128 * f_i,
        tile_w: 128,
        tile_h: 128,
        primitive_marker: :sprite
      }
    end

    def feathers_amount
      {
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
    end

    def encounters_amount
      {
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

    def base_misc_button_rect
      {
        x: GTK.args.grid.w - 128 - 32 - 16,
        y: GTK.args.grid.h - 16 - 32,
        w: 32,
        h: 32
      }
    end
  end
end
