class ComboManager
  attr :current_sequence, :combo_completed, :current_combo_sequence_path, :next_combo_ingredient

  def initialize
    @current_sequence = []
    @current_combo_sequence_path = {}
    @next_combo_ingredient = ""
    @combo_completed = false
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
    @combo_completed = combo_completed?(@current_sequence, matched_combo_sequence[:sequence])
    @current_combo_sequence_path = matched_combo_sequence
    next_index = @current_sequence.length || 0
    @next_combo_ingredient = @current_combo_sequence_path[:sequence][next_index]
  end

  def reset_sequence(end_of_combo = false)
    @current_combo_sequence_path = {}
    @combo_completed = false
    last_value = @current_sequence.last
    @current_sequence.clear
    @current_sequence << last_value if !end_of_combo
  end

  def ing_image?(ing_id)
    $IIDS[ing_id].path
  end

  def prefab
    if @current_combo_sequence_path && @current_combo_sequence_path != {}


      screen_width = 1280
      icon_w      = 64
      icons       = @current_combo_sequence_path[:sequence]
      total_w = icons.size * icon_w
      start_x = (screen_width - total_w) / 2

      combo_icons = []
      @current_combo_sequence_path[:sequence].each_with_index do |ing_id, i|
        alpha = (i < @current_sequence.length) ? 255 : 100
        combo_icons << {
          x: start_x + i * icon_w,
          y: 256 - 16,
          w: 64,
          h: 64,
          path: ing_image?(ing_id),
          a: alpha,
          primitive_marker: :sprite
        }
      end

      [combo_icons]
    end
  end
end