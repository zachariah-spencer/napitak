class CombatStatsComponent
  attr_gtk
  attr :hp, :max_hp, :dead, :statuses, :status_types, :focus, :max_focus, :mod_max_focus

  def initialize(hp: 1, focus: 0)
    @statuses = {
      $STATUS_TYPES["SCORCH"] => 0,
      $STATUS_TYPES["BLIGHT"] => 0,
      $STATUS_TYPES["FROST"] => 0,
      $STATUS_TYPES["WARD"] => 0,
      $STATUS_TYPES["RESTORATION"] => 0,
    }
    @hp = hp
    @max_hp = hp
    @focus = focus
    @max_focus = focus
    @mod_max_focus = focus
    @ward = 0
    @dead = false
  end

  def heal(amt)
    @hp += amt
    @hp = @max_hp if @hp > @max_hp
  end

  def hurt(amt)
    puts "here"
    remaining_damage = amt - @ward

    if remaining_damage <= 0
      @ward -= amt
      return
    else
      @ward = 0
      @hp -= amt
      @hp = 0 if @hp < 0
    end

    @dead = true if dead?
  end

  def reset!
    @hp = @max_hp
    @dead = false
    @statuses = {
      $STATUS_TYPES["SCORCH"] => 0,
      $STATUS_TYPES["BLIGHT"] => 0,
      $STATUS_TYPES["FROST"] => 0,
      $STATUS_TYPES["WARD"] => 0,
      $STATUS_TYPES["RESTORATION"] => 0,
    }
  end

  def dead?
    @hp <= 0
  end

  # If is_turn is false then it is the end of round calc
  # TAKES A STRING
  def calc_status(type:)
    type_enum = $STATUS_TYPES[type]
    stacks = @statuses[type_enum]
    puts "#{type} || #{type_enum} || #{stacks}"

    case type_enum
    when $STATUS_TYPES["SCORCH"]
      
      if stacks > 0
        puts "SCORCH"
        hurt(stacks)
        @statuses[$STATUS_TYPES["SCORCH"]] -= 1
      end
    when $STATUS_TYPES["BLIGHT"]
      if stacks > 0
        hurt(stacks)
      end
    when $STATUS_TYPES["FROST"]
      if stacks > 0
        @statuses[$STATUS_TYPES["FROST"]] -= 1
      end
    when $STATUS_TYPES["RESTORATION"]
      if stacks > 0
        heal(stacks)
        @statuses[$STATUS_TYPES["RESTORATION"]] -= 1
      end
    end

    # puts @statuses
  end

  # type: String || stacks: int
  # Applies stacks of a certain status type.
  def apply_status(type:, stacks:)
    @statuses[$STATUS_TYPES[type]] += stacks
  end
end