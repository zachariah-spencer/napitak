class CombatStatsComponent
  attr_gtk
  attr :hp, :max_hp, :dead, :statuses, :status_types, :focus, :max_focus, :mod_max_focus

  def initialize(hp: 1, focus: 0, x: , y:)
    @statuses = {
      $STATUS_TYPES["SCORCH"] => 0,
      $STATUS_TYPES["BLIGHT"] => 0,
      $STATUS_TYPES["FROST"] => 0,
      $STATUS_TYPES["WARD"] => 0,
      $STATUS_TYPES["RESTORATION"] => 0,
    }
    @x = x
    @y = y
    @entity_id = new_id?
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

  def tick; end

  # If is_turn is false then it is the end of round calc
  # TAKES A STRING
  def calc_status(type:)
    type_enum = $STATUS_TYPES[type]
    stacks = @statuses[type_enum]

    case type_enum
    when $STATUS_TYPES["SCORCH"]
      
      if stacks > 0
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

  def status_color?(type_enum)
    case type_enum
    when $STATUS_TYPES["SCORCH"]
      return [255, 100, 0]
    when $STATUS_TYPES["BLIGHT"]
      return [120, 150, 60]
    when $STATUS_TYPES["FROST"]
      return [0, 255, 255]
    when $STATUS_TYPES["WARD"]
      return [255, 255, 0]
    when $STATUS_TYPES["RESTORATION"]
      return [0, 255, 0]
    end
  end

  def prefab()
    rt_paths = []
    @statuses.each do |type, stacks|
      if stacks > 0 and type != $STATUS_TYPES["WARD"]
        path = "c_stat_#{@entity_id}_#{type}".to_s
        GTK.args.outputs[path].w = 50
        GTK.args.outputs[path].h = 50

        color = status_color?(type)
        GTK.args.outputs[path] << {
          x: 0,
          y: 0,
          w: 50,
          h: 50,
          r: color[0],
          g: color[1],
          b: color[2],
          path: "sprites/circle/white.png",
          primitive_marker: :sprite,
        }

        GTK.args.outputs[path] <<
        {
          x: 25,
          y: 25,
          anchor_x: 0.5,
          anchor_y: 0.5,
          text: "#{stacks}",
          size_enum: 8,
          alignment_enum: 0,
          r: 0,
          g: 0,
          b: 0,
          a: 255,
          primitive_marker: :label,
        }

        rt_paths << path
      end
    end

    stack_sprites = []
    start_x = @x - (rt_paths.size * 75 / 2)
    rt_paths.each_with_index do |path, i|
      stack_sprites << {
        x: start_x + (i * 75),
        y: @y,
        w: 50,
        h: 50,
        path: path,
        primitive_marker: :sprite
      }
    end

    stack_sprites
  end
end