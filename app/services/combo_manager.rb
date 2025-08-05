class ComboManager
  attr :current_sequence, :combo_completed, :current_combo_sequence_path

  def initialize
    @current_sequence = []
    @current_combo_sequence_path = nil
    @combo_completed = false
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

  def tick
    find_matching_combo
  end

  def current_sequence_combo?(current_sequence, valid_combo_sequence)
    return false if current_sequence.empty?
    valid_combo_sequence.take(current_sequence.size) == current_sequence
    #enumerator = valid_combo_sequence.each
    #current_sequence.all? { |potion_combo_ing_id| enumerator.any? { |possible_combo_ing_id| possible_combo_ing_id == potion_combo_ing_id }}
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
  end

  def reset_sequence(end_of_combo = false)
    @current_combo_sequence_path = nil
    @combo_completed = false
    last_value = @current_sequence.last
    @current_sequence.clear
    @current_sequence << last_value if !end_of_combo
  end

  def prefab; end
end