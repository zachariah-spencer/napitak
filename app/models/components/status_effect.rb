class StatusEffect
  attr_gtk
  attr

  # can take RP encounter effects and apply them, track their duration, and end them
  def initialize(effect:, value:, duration:, encounters_since_started: 0)
    @effect = effect
    @value = value
    @duration = duration
    @encounters_since_started = encounters_since_started

    apply
  end

  def label?
    text = ""
    case @effect
    when "modify_max_hp"
      sign = (@value > -1) ? "+" : ""
      text << "Max HP       #{sign}#{@value}"
      text << "        #{@duration} Encounters" if !@duration.is_a?(String)
    when "modify_max_focus"
      sign = (@value > -1) ? "+" : ""
      text << "Max Focus        #{sign}#{@value}"
      text << "        #{@duration} Encounters" if !@duration.is_a?(String)
    when "vulnerable"
      text << "Vulnerable to All"
      text << "        #{@duration} Encounters" if !@duration.is_a?(String)
    when "vulnerable_cold"
      text << "Vulnerable to Cold"
      text << "        #{@duration} Encounters" if !@duration.is_a?(String)
    when "resist_poison"
      text << "Resistant to Poison"
      text << "        #{@duration} Encounters" if !@duration.is_a?(String)
    end

    text
  end

  def save_data?
    {
      effect: @effect,
      value: @value,
      duration: @duration,
      encounters_since_started: @encounters_since_started
    }
  end

  def apply
    case @effect
    when "modify_max_hp"
      puts "MODIFY MAX HP: #{@value.to_i} || PLAYERS MAX HP: #{$player.maximum_hp}"
      $player.maximum_hp += @value.to_i
      $player.maximum_hp = 0 if $player.maximum_hp < 0
      $player.combat_stats.reset!($player.maximum_hp, $player.maximum_focus)
      $player.combat_stats.dead = true if $player.combat_stats.dead?
      puts "PLAYER IS DEAD? :: #{$player.combat_stats.dead}"
      $player.combat_stats.dead_tick =
        Kernel.tick_count if $player.combat_stats.dead
      #$GAME.end_run if $player.maximum_hp <= 0
      puts "PLAYERS MAX HP AFTER MOD: #{$player.maximum_hp}"
    when "modify_max_focus"
      puts "MODIFY MAX FOCUS"
      $player.maximum_focus += @value.to_i
      $player.maximum_focus = 0 if $player.maximum_focus < 0
    when "vulnerable"
      puts "VULNERABLE"
      $DAMAGE_TYPES.each { |k, v| $player.combat_stats.vulnerabilities << v }
      puts $player.combat_stats.vulnerabilities
    when "modify_feathers"
      puts "MODIFY FEATHER COUNT"
      $player.feathers += @value.to_i
    when "vulnerable_cold"
      puts "VULNERABLE TO COLD"
      $player.combat_stats.vulnerabilities << $DAMAGE_TYPES[:cold]
    when "resist_poison"
      puts "RESISTANT TO POISON"
      $player.combat_stats.resistances << $DAMAGE_TYPES[:disease]
    end
  end

  def stop
    puts "STOPPING EFFECT \n\n"
    case @effect
    when "modify_max_hp"
      puts "MODIFY MAX HP STOPPED"
      $player.maximum_hp -= @value.to_i
      puts $player.maximum_hp
    when "modify_max_focus"
      puts "MODIFY MAX FOCUS"
      $player.maximum_focus -= @value.to_i
    when "vulnerable"
      puts "VULNERABLE"
      $DAMAGE_TYPES.each { |k, v| $player.combat_stats.vulnerabilities.clear }
      puts $player.combat_stats.vulnerabilities
    when "vulnerable_cold"
      puts "VULNERABLE TO COLD"
    when "resist_poison"
      puts "RESISTANT TO POISON"
    end

    $player.status_effects.reject! { |effect| effect == self }
  end

  def calc_duration
    if @encounters_since_started <= 0
      @encounters_since_started += 1
      puts @encounters_since_started
      return
    end
    if !@duration.is_a?(String)
      @duration -= 1
      puts "DURATION UPDATE: #{@duration}"
      stop if @duration <= 0
    end
  end
end
