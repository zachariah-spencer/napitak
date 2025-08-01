class StatusEffect
  attr_gtk
  attr

  # can take RP encounter effects and apply them, track their duration, and end them
  def initialize(effect:, value:, duration:)
    @effect = effect
    @value = value
    @duration = duration

    if @duration != "instant" || @duration != "run"
      puts "effect has a duration"
    end

    apply
  end

  def label?
    case @effect
    when "modify_max_hp"
      sign = (@value > -1) ? "+" : "-"
      return "Max HP | #{sign}#{@value}"
      
    when "modify_max_focus"
      sign = (@value > -1) ? "+" : "-"
      return "Max Focus | #{sign}#{@value}"

    when "vulnerable"
      return "Vulnerable to All Damage"
    when "vulnerable_cold"
      return "Vulnerable to Cold"
    when "resist_poison"
      return "Resistant to Poison"
    end
    
  end

  def apply
    case @effect
      when "modify_max_hp"
      puts "MODIFY MAX HP"
      $player.maximum_hp += @value.to_i
      puts $player.maximum_hp
    when "modify_max_focus"
      puts "MODIFY MAX FOCUS"
      $player.maximum_focus += @value.to_i
    when "vulnerable"
      puts "VULNERABLE"
      $DAMAGE_TYPES.each { |k,v| $player.combat_stats.vulnerabilities << v }
      puts $player.combat_stats.vulnerabilities
    when "modify_feathers"
      puts "MODIFY FEATHER COUNT"
    when "add_random_ingredients"
      puts "ADD RANDOM INGREDIENTS TO SATCHEL"
    when "vulnerable_cold"
      puts "VULNERABLE TO COLD"
    when "resist_poison"
      puts "RESISTANT TO POISON"
    end
    
    # $player.maximum_hp += value.to_i
  end

  def end
    
  end

  def calc_duration
    
  end
end