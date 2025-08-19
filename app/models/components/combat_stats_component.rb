# frozen_string_literal: true

class CombatStatsComponent
  attr_gtk
  attr :hp,
       :max_hp,
       :dead,
       :statuses,
       :status_types,
       :focus,
       :max_focus,
       :bonus_focus,
       :mod_max_focus,
       :ward,
       :dead_tick,
       :resistances,
       :vulnerabilities,
       :accuracy_mod
  def initialize(
    x:,
    y:,
    hp: 1,
    focus: 0,
    resistances: [],
    vulnerabilities: [],
    columns: 8
  )
    @statuses = {
      $STATUS_TYPES[:SCORCH] => 0,
      $STATUS_TYPES[:BLIGHT] => 0,
      $STATUS_TYPES[:FROST] => 0,
      $STATUS_TYPES[:WARD] => 0,
      $STATUS_TYPES[:RESTORATION] => 0,
      $STATUS_TYPES[:BLIND] => 0
    }

    @resistances = resistances
    @vulnerabilities = vulnerabilities
    @x = x
    @y = y
    @columns = columns
    @entity_id = GameUtils.new_id?
    @hp = hp
    @max_hp = hp
    @focus = focus
    @max_focus = focus
    @mod_max_focus = focus
    @bonus_focus = 0
    @accuracy_mod = 0.0
    @ward = 0
    @dead = false
    @dead_tick = nil
  end

  def heal(amt)
    @hp += amt
    @hp = @max_hp if @hp > @max_hp
    GameUtils.status_label(GTK.args.grid.w / 2, @y, "#{amt}", 0, 255, 0, 100)
  end

  def channel(amt)
    @bonus_focus += amt
    GameUtils.status_label(GTK.args.grid.w / 2, @y, "#{amt}", 0, 150, 150, 100)
  end

  def consume_bonus_focus
    consumed_focus = @bonus_focus
    @bonus_focus = 0
    consumed_focus
  end

  def hurt(amt, type)
    # $AUDIO_SERVICE.play_sound(:hit_impact)
    vulnerable = @vulnerabilities.include?(type)
    resistant = @resistances.include?(type)

    mod_amt = amt
    mod_amt = (amt * 1.5).ceil if vulnerable
    mod_amt = (amt * 0.5).ceil if resistant

    remaining_damage = mod_amt - (@statuses[$STATUS_TYPES[:WARD]] * 2)

    if remaining_damage <= 0
      @statuses[$STATUS_TYPES[:WARD]] -= mod_amt / 2
      return
    else
      @statuses[$STATUS_TYPES[:WARD]] = 0
      @hp -= remaining_damage
      @hp = 0 if @hp < 0
    end

    GameUtils.status_label(
      GTK.args.grid.w / 2,
      @y,
      "#{mod_amt}",
      255,
      0,
      0,
      100
    )
    if vulnerable
      GameUtils.status_label(
        GTK.args.grid.w / 2,
        @y,
        "VULNERABLE",
        255,
        255,
        255,
        100
      )
    end
    if resistant
      GameUtils.status_label(
        GTK.args.grid.w / 2,
        @y,
        "RESISTANT",
        255,
        255,
        255,
        100
      )
    end
    @dead = true if dead?
    @dead_tick = Kernel.tick_count if @dead
  end

  def validate_upgrades(max_hp, max_focus)
    @max_hp = max_hp
    @max_focus = max_focus
  end

  def tick
  end

  def reset!(max_hp, max_foc)
    validate_upgrades(max_hp, max_foc)
    @hp = @max_hp
    @focus = @max_focus
    @dead = false
    @dead_tick = nil
    @accuracy_mod = 0.0
    @statuses = {
      $STATUS_TYPES[:SCORCH] => 0,
      $STATUS_TYPES[:BLIGHT] => 0,
      $STATUS_TYPES[:FROST] => 0,
      $STATUS_TYPES[:WARD] => 0,
      $STATUS_TYPES[:RESTORATION] => 0,
      $STATUS_TYPES[:BLIND] => 0,
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
    color = status_color?(type_enum)

    case type_enum
    when $STATUS_TYPES[:SCORCH]
      if stacks > 0
        hurt(stacks, $DAMAGE_TYPES[:heat])
        @statuses[$STATUS_TYPES[:SCORCH]] -= 1
        GameUtils.status_label(
          GTK.args.grid.w / 2,
          @y,
          "-1",
          color[0],
          color[1],
          color[2],
          80
        )
      end
    when $STATUS_TYPES[:BLIGHT]
      hurt(stacks, $DAMAGE_TYPES[:disease]) if stacks > 0
    when $STATUS_TYPES[:FROST]
      if stacks > 0
        @statuses[$STATUS_TYPES[:FROST]] -= 1
        GameUtils.status_label(
          GTK.args.grid.w / 2,
          @y,
          "-1",
          color[0],
          color[1],
          color[2],
          80
        )
      end
    when $STATUS_TYPES[:RESTORATION]
      if stacks > 0
        heal(stacks)
        @statuses[$STATUS_TYPES[:RESTORATION]] -= 1
        GameUtils.status_label(
          GTK.args.grid.w / 2,
          @y,
          "-1",
          color[0],
          color[1],
          color[2],
          80
        )
      end
    when $STATUS_TYPES[:BLIND]
      if stacks > 0
        @accuracy_mod = -stacks
        @statuses[$STATUS_TYPES[:BLIND]] -= 5
        GameUtils.status_label(
          GTK.args.grid.w / 2,
          @y,
          "-5",
          color[0],
          color[1],
          color[2],
          80
        )
      end
    end

    @dead = true if dead?
    @dead_tick = Kernel.tick_count if @dead
  end

  # type: String || stacks: int
  # Applies stacks of a certain status type.
  def apply_status(type:, stacks:)
    calc_status_tutorial(type: type)
    @statuses[$STATUS_TYPES[type]] += stacks
    color = status_color?($STATUS_TYPES[type])
    GameUtils.status_label(
      GTK.args.grid.w / 2,
      @y - 100,
      "#{$STATUS_EFFECT_COLORS[$STATUS_TYPES[type]][:message]} +#{stacks}",
      color[0],
      color[1],
      color[2],
      80
    )

    @accuracy_mod = -@statuses[$STATUS_TYPES[:BLIND]] if type == :BLIND
  end

  def calc_status_tutorial(type:)
    case type
    when :FROST
      if !$files.save_data["tutorials"]["frost"]
        $files.save_data["tutorials"]["frost"] = true
        puts "PLAY TUTORIAL FOR FROST"
        $TUTORIAL_INDEX = 30
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
        $TUTORIAL_INDEX = 31
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
      end
    when :BLIGHT
      if !$files.save_data["tutorials"]["blight"]
        $files.save_data["tutorials"]["blight"] = true
        puts "PLAY TUTORIAL FOR BLIGHT"
        $TUTORIAL_INDEX = 32
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
      end
    when :WARD
      if !$files.save_data["tutorials"]["ward"]
        $files.save_data["tutorials"]["ward"] = true
        puts "PLAY TUTORIAL FOR WARD"
        $TUTORIAL_INDEX = 34
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
        $TUTORIAL_INDEX = 35
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
      end
    when :RESTORATION
      if !$files.save_data["tutorials"]["restoration"]
        $files.save_data["tutorials"]["restoration"] = true
        puts "PLAY TUTORIAL FOR RESTORATION"
        $TUTORIAL_INDEX = 36
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
        $TUTORIAL_INDEX = 37
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
      end
    when :BLIND
      if !$files.save_data["tutorials"]["blind"]
        $files.save_data["tutorials"]["blind"] = true
        puts "PLAY TUTORIAL FOR BLIND"
        $TUTORIAL_INDEX = 38
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
        $TUTORIAL_INDEX = 39
        id, text = GameUtils.tutorial_string?($TUTORIAL_INDEX)
        GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id)
      end
    end

    # FIXME: Save tutorials played to $files.save_data here
  end

  def status_color?(type_enum)
    color = $STATUS_EFFECT_COLORS[type_enum]
    [color[:r], color[:g], color[:b]]
  end

  def prefab()
    rt_paths = []
    stack_sprites = []
    
    @statuses.each do |type, stacks|
      path = "c_stat_#{@entity_id}_#{type}".to_s
      if stacks > 0
        GTK.args.outputs[path].w = 32
        GTK.args.outputs[path].h = 32
        if type != $STATUS_TYPES[:WARD]
          color = status_color?(type)
          GTK.args.outputs[path] << {
            x: 0,
            y: 0,
            w: 32,
            h: 32,
            r: color[0],
            g: color[1],
            b: color[2],
            path: "sprites/circle/white.png",
            primitive_marker: :sprite
          }

          GTK.args.outputs[path] << {
            x: 16,
            y: 16,
            anchor_x: 0.5,
            anchor_y: 0.5,
            text: "#{stacks}",
            size_px: 18,
            font: $FONT,
            alignment_enum: 0,
            r: 0,
            g: 0,
            b: 0,
            a: 255,
            primitive_marker: :label
          }
          rt_paths << path
        elsif stacks > 0 && type == $STATUS_TYPES[:WARD]
          stack_sprites << {
            x: @x,
            y: @y - 32,
            anchor_x: 0.5,
            anchor_y: 0.5,
            text: "#{stacks}",
            size_px: 18,
            font: $FONT,
            alignment_enum: 0,
            r: $STATUS_EFFECT_COLORS[$STATUS_TYPES[:WARD]][:r],
            g: $STATUS_EFFECT_COLORS[$STATUS_TYPES[:WARD]][:g],
            b: $STATUS_EFFECT_COLORS[$STATUS_TYPES[:WARD]][:b],
            a: 255,
            primitive_marker: :label
          }
        end
      end
    end

    # total width of the whole row:
    if rt_paths.size > 2
      total_width = 2 * 32 + (2 - 1) * 8
    else
      total_width = rt_paths.size * 32 + (rt_paths.size - 1) * 8
    end
    # x of the very first icon so that row is centered on @x:
    start_x = @x - total_width / 2.0
    rt_paths.each_with_index do |path, i|
      stack_sprites << {
        x: start_x + i % 2 * (32 + 8),
        y: @y - 80 - ((i / 2).floor * (32 + 8)),
        w: 32,
        h: 32,
        path: path,
        primitive_marker: :sprite
      }
    end

    stack_sprites
  end
end
