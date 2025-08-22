class CardHandManager
  attr_gtk
  attr_reader :hand

  def initialize(player:, enemy:, combo_manager:, max_hand_size: 5)
    @player = player
    @enemy = enemy
    @combo_manager = combo_manager
    @max_hand_size = max_hand_size
    @hand = {}
  end

  def draw_card
    if @player.potions.all_cards.size <= 0
      GameUtils.status_label(700, 50, "NO CARDS IN DECK", 255, 255, 255, 40)
    end
    if @hand.size >= @max_hand_size
      GameUtils.status_label(700, 50, "NO ROOM IN HAND", 255, 255, 255, 40)
    end
    if @player.potions.all_cards.size > 0 && @hand.size < @max_hand_size
      card = @player.potions.draw(true)
      card.instant_set_position(x: 64, y: 64)
      @hand[card.entity_id] = card
    end
  end

  def actions_available?
    @player.combat_stats.focus > 0 && @hand.length >= 1
  end

  def calc_card_positions
    @hand.each_with_index do |(id, card), i|
      card.calc_position(@hand.length, i)
      card.tick
    end
  end

  def cleanup
    @hand.each { |_id, card| @player.potions.add(card) }
    @hand.clear
  end

  def remove_marked
    @hand.reject! { |_id, c| c.needs_removed }
  end

  def get_card_rects
    @hand.values.map(&:rect)
  end

  def consume_card(card)
    potion_info = $PIDS[card.id]
    applied_fc = (potion_info.fc + card.focus_mod)
    if @player.combat_stats.focus >= applied_fc && card.uses_left > 0
      @player.combat_stats.focus -= applied_fc
      card.uses_left -= 1
      card.update_sprite
      @player.potions.discard card
      @hand.delete card.entity_id
    end
  end

  def use_card(card)
    potion_info = $PIDS[card.id]
    applied_fc = (potion_info.fc + card.focus_mod)
    if @player.combat_stats.focus >= applied_fc && card.uses_left > 0
      @player.combat_stats.focus -= applied_fc
      card.uses_left -= 1
      card.update_sprite
      @player.potions.discard card
      @hand.delete card.entity_id

      potion_traits = potion_info.traits

      if potion_info.cast_animation
        $game.input_locked = true
        $player.potion_animations.play_animation(potion_info.cast_animation)
      end

      $AUDIO_SERVICE.play_sound(potion_info.cast_sfx) if potion_info.cast_sfx
    end

    def calc_card_effects(potion)
      return if !$player.check_hit?
      potion_info = potion
      potion_traits = potion_info.traits
      if @combo_manager.combo_completion_tick
        if potion_info[:finisher_trait]
          puts "DO A SPECIFIC FINISHER EFFECT"
          puts "#{potion_info[:finisher_trait]}"
          potion_traits = potion_info.traits + [potion_info[:finisher_trait]]
        end
      end

      damage_trait = potion_traits.find { |h| h.key?($CARD_TRAITS[:damage]) }
      damage_trait &&= damage_trait[$CARD_TRAITS[:damage]]
      mend_trait = potion_traits.find { |h| h.key?($CARD_TRAITS[:mend]) }
      mend_trait &&= mend_trait[$CARD_TRAITS[:mend]]
      restoration_trait =
        potion_traits.find { |h| h.key?($CARD_TRAITS[:restoration]) }
      restoration_trait &&= restoration_trait[$CARD_TRAITS[:restoration]]
      scorch_trait = potion_traits.find { |h| h.key?($CARD_TRAITS[:scorch]) }
      scorch_trait &&= scorch_trait[$CARD_TRAITS[:scorch]]
      blight_trait = potion_traits.find { |h| h.key?($CARD_TRAITS[:blight]) }
      blight_trait &&= blight_trait[$CARD_TRAITS[:blight]]
      frost_trait = potion_traits.find { |h| h.key?($CARD_TRAITS[:frost]) }
      frost_trait &&= frost_trait[$CARD_TRAITS[:frost]]
      ward_trait = potion_traits.find { |h| h.key?($CARD_TRAITS[:ward]) }
      ward_trait &&= ward_trait[$CARD_TRAITS[:ward]]
      channel_trait = potion_traits.find { |h| h.key?($CARD_TRAITS[:channel]) }
      channel_trait &&= channel_trait[$CARD_TRAITS[:channel]]
      blind_trait = potion_traits.find { |h| h.key?($CARD_TRAITS[:blind]) }
      blind_trait &&= blind_trait[$CARD_TRAITS[:blind]]

      @enemy.hurt(damage_trait[:amount], damage_trait[:type]) if damage_trait
      @player.combat_stats.heal(mend_trait) if mend_trait
      if restoration_trait
        @player.combat_stats.apply_status(
          type: :RESTORATION,
          stacks: restoration_trait
        )
      end
      if scorch_trait
        @enemy.combat_stats.apply_status(type: :SCORCH, stacks: scorch_trait)
      end
      if blight_trait
        @enemy.combat_stats.apply_status(type: :BLIGHT, stacks: blight_trait)
      end
      if frost_trait
        @enemy.combat_stats.apply_status(type: :FROST, stacks: frost_trait)
      end
      if ward_trait
        @player.combat_stats.apply_status(type: :WARD, stacks: ward_trait)
      end
      @player.combat_stats.channel(channel_trait) if channel_trait
      if blind_trait
        @enemy.combat_stats.apply_status(type: :BLIND, stacks: blind_trait)
      end

      if @combo_manager.combo_completion_tick
        $game.input_locked = true
        combo_effect = @combo_manager.current_combo_sequence_path[:effect]

        GameUtils.status_label(
          1280 / 2,
          256,
          "COMBO COMPLETED",
          255,
          0,
          255,
          32
        )
        # DO COMBO STUFF
        @player.combat_stats.focus = @player.combat_stats.max_focus

        case combo_effect
        when "scorch_doubles"
          @enemy.combat_stats.hurt(5, $DAMAGE_TYPES[:force])
        else
        end
      end
    end
  end
end
