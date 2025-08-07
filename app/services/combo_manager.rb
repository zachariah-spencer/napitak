class ComboManager
  attr :current_sequence, :combo_completion_tick, :current_combo_sequence_path, :next_combo_ingredient

  def initialize
    @current_sequence = []
    @current_combo_sequence_path = {}
    @current_combo_images = []
    @next_combo_ingredient = ""
    @da = 0
    @a = 0
    @combo_completion_tick = nil
    @possible_sequences = [
      # two fire sequences
      {
        sequence: ["i003", "i002", "i003"],
        effect: "scorch_doubles"
      },
      {
        sequence: ["i003", "i004", "i002"],
        effect: "ward_doubles"
      },
      # water sequence and following elements
      {
        sequence: ["i002", "i003", "i002"],
        effect: "regen_5"
      },
      {
        sequence: ["i004", "i005", "i004"],
        effect: "something"
      },
      {
        sequence: ["i005", "i004", "i005"],
        effect: "something else"
      }
    ]
  end

  def tick(hand)
    reset_sequence(true) if @combo_completion_tick && @combo_completion_tick.elapsed_time >= 1.5.seconds

    find_matching_combo

    (hand.values + $player.potions.all_cards).each do |card|
      card.focus_mod = 0
      card.focus_mod = -1 if (card.primary_base_ingredient_id? == @next_combo_ingredient) && @next_combo_ingredient != ""
    end
  end

  def current_sequence_combo?(current_sequence, valid_combo_sequence)
    return false if current_sequence.empty?
    valid_combo_sequence.take(current_sequence.size) == current_sequence
  end

  def combo_completed?(current_combo_sequence, valid_matching_combo_sequence)
    current_combo_sequence.size == valid_matching_combo_sequence.size && current_combo_sequence == valid_matching_combo_sequence
  end

  def add_to_sequence(primary_base_ingredient_id)
    @current_sequence << primary_base_ingredient_id
    find_matching_combo 
  end

  def find_matching_combo
    first_matching_combo_sequence = @possible_sequences.find do |possible_sequence_hash|
      current_sequence_combo?(@current_sequence, possible_sequence_hash[:sequence])
    end

    #puts "Current_Sequence: #{@current_sequence}"

    #puts "COMBO COMPLETED: #{@combo_completed}"
    if first_matching_combo_sequence
      #puts "Matched Sequence: #{first_matching_combo_sequence.inspect}"
      update_sequence_state(first_matching_combo_sequence)
    else
      #puts "No Matches Found"
      reset_sequence
    end
  end

  def update_sequence_state(matched_combo_sequence)
    @combo_completion_tick = Kernel.tick_count if combo_completed?(@current_sequence, matched_combo_sequence[:sequence]) && !@combo_completion_tick
    is_new_path = @current_combo_sequence_path != matched_combo_sequence
    @current_combo_sequence_path = matched_combo_sequence

    if current_combo_path_valid? && is_new_path
      @current_combo_images.clear
      screen_width = 1280
      icon_w = 64
      icons = @current_combo_sequence_path[:sequence]
      total_w = icons.length * icon_w
      start_x = (screen_width - total_w) / 2

      @current_combo_sequence_path[:sequence].each_with_index do |ing_id, i|
        @current_combo_images << {
          x: start_x + i * icon_w,
          y: 256 - 16,
          w: 64,
          h: 64,
          path: ing_image?(ing_id),
          primitive_marker: :sprite
        }
      end
    end
    next_index = @current_sequence.length || 0
    @next_combo_ingredient = @current_combo_sequence_path[:sequence][next_index]
  end

  def reset_sequence(end_of_combo = false)
    $game.input_locked = false
    @current_combo_sequence_path = {}
    @combo_completion_tick = nil
    last_value = @current_sequence.last
    @current_sequence.clear
    @current_sequence << last_value if !end_of_combo
  end

  def ing_image?(ing_id)
    $IIDS[ing_id].path
  end

  def current_combo_path_valid?
    (@current_combo_sequence_path && @current_combo_sequence_path != {})
  end

  def prefab
    if ((@current_combo_sequence_path && @current_combo_sequence_path != {}) && !@combo_completion_tick) || @combo_completion_tick && @combo_completion_tick.elapsed_time < 0.5.seconds
      @da = 255
    elsif @combo_completion_tick && @combo_completion_tick.elapsed_time >= 0.5.seconds
      @da = 0
    else
      @da = 0
    end

    @a = @a.lerp(@da, 0.075)

    @current_combo_images.each_with_index do |sprite, i|
      if @combo_completion_tick
        alpha = @a
      else
        alpha = (@current_sequence.length > i) ? @a : (@a / 4)
      end

      sprite.merge!(a: alpha)
    end

    [@current_combo_images]
  end
end