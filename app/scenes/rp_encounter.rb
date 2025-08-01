class RoleplayEncounter < Scene
  attr :sc_id

  # pseudocode
  # what the hell does this class do???

  # shows some art work (splash art)

  # incrementally display some flavor text prompt

  # upon completion of the flavor text or if the user left clicks, present the player with x number of option
  # buttons describing actions they can take as a reaction to the prompt

  # weigh the probability of a good, bad, or neutral outcome based on the player's selected action

  # display the result of the player's action along with some new splash art (good/bad/neutral outcome art)

  # penalize or reward the player based on specific outcomes

  # await a left click to leave encounter

  def initialize()
    puts "init Roleplay Encounter"
    @sc_id = "rp_encounter_generic"

    @OUTCOMES = { undetermined: 0, bad: 1, neutral: 2, good: 3 }
    @outcome = @OUTCOMES[:undetermined]
    @consequence = {}

    @options
    @options_alpha = 0
    @option_selected_tick = nil

    @message
    @message_displaying_tick = nil
    @message_completed = false
    @result_message_completed = false

    load_encounter_from_json
  end

  def load_encounter_from_json
    encounters_json = GTK.read_file("data/rp_encounters.json")
    encounters_hash = GTK.parse_json(encounters_json)
    specific_encounter_hash = encounters_hash[encounters_hash.keys.sample]

    @options = specific_encounter_hash["options"]
    @options.shuffle!
    play_message(specific_encounter_hash["prompt"])
  end

  def ready
  end

  def play_message(message, is_outcome: false)
    @message_displaying_tick = Kernel.tick_count

    if is_outcome
      @message = message["flavor"] + " " + message["consequence"]
    else
      @message = message
    end
  end

  def incremented_text?()
    m = ""
    num_chars_to_display = (@message_displaying_tick.elapsed_time / 4).floor
    m << @message[0, num_chars_to_display] if @message_displaying_tick
    @message_completed = true if @message_displaying_tick &&
      num_chars_to_display >= @message.size && !@option_selected_tick
    @result_message_completed = true if @message_displaying_tick &&
      num_chars_to_display >= @message.size && @option_selected_tick
    m
  end

  def cleanup
  end

  def leave
    calc_outcome

    $game.change_scene(prev_sc: @sc_id, next_scene: "map") if !$game.transitioning_scenes
  end

  def tick
    @outcome += 1 if GTK.args.inputs.keyboard.key_down.j

    if GTK.args.inputs.mouse.click
      @options.each_with_index do |o, i|
        if o["rect"] && GTK.args.inputs.mouse.inside_rect?(o["rect"])
          puts "ROLLING PROBABILITY MATH FOR #{o["text"]}"
          determine_outcome(o)
        end
      end

      @message_displaying_tick = -1000 if @message_completed == false ||
        @option_selected_tick && @result_message_completed == false &&
          @option_selected_tick.elapsed_time >= 0.1.seconds

      leave if @option_selected_tick && @result_message_completed && !$game.input_locked
    end
  end

  def determine_outcome(option)
    roll = Numeric.rand(0..20)
    dc = option["dc"]
    if roll >= dc
      @outcome = @OUTCOMES[:good]
      play_message(option["outcome_messages"]["GOOD"], is_outcome: true)
      @consequence = option["outcomes"]["GOOD"]
    elsif roll < dc && dc - roll <= 5
      @outcome = @OUTCOMES[:neutral]
      play_message(option["outcome_messages"]["NEUTRAL"], is_outcome: true)
    else
      roll < dc && dc - roll > 5
      @outcome = @OUTCOMES[:bad]
      play_message(option["outcome_messages"]["BAD"], is_outcome: true)
      @consequence = option["outcomes"]["BAD"]
    end

    @options.each { |o| o["rect"] = nil }
    @option_selected_tick = Kernel.tick_count
  end

  def calc_outcome
    # find a way to make blessings or penalties for the player when specific scenarios play out
    # 
    # possible effects
      # initiate_combat wolf DONE
      # initiate_combat bat BASICALLY DONE (NEED BAT ENCOUNTER)
      # modify_max_hp int
      # modify_max_focus int
      # vulnerable
      # modify_feathers int
      # add_random_ingredients array_of_ing_ids
      # vulnerable_cold
      # resist_poison
    effect = @consequence["effect"]
    value = @consequence["value"]
    duration = @consequence["duration"]

    puts "EFFECT: #{effect}\nVALUE: #{value}\nDURATION: #{duration}"
    case effect
    when "initiate_combat"
      case value
      when "wolf"
        puts "START WOLF FIGHT"
        $game.change_scene(
            prev_sc: @sc_id,
            next_scene: "combat",
            args: ["wolf"]
          )
      when "bat"
        puts "START BAT FIGHT"
        # Insert bat fight here when it exists
      end
    when "modify_max_hp"
      puts "MODIFY MAX HP"
    when "modify_max_focus"
      puts "MODIFY MAX FOCUS"
    when "vulnerable"
      puts "VULNERABLE"
    when "modify_feathers"
      puts "MODIFY FEATHER COUNT"
    when "add_random_ingredients"
      puts "ADD RANDOM INGREDIENTS TO SATCHEL"
    when "vulnerable_cold"
      puts "VULNERABLE TO COLD"
    when "resist_poison"
      puts "RESISTANT TO POISON"
    end
  end

  def render_splash_art
    case @outcome
    when @OUTCOMES[:undetermined]
      {
        x: 256,
        y: 256,
        w: GTK.args.grid.w - 512,
        h: GTK.args.grid.h - 512,
        r: 100,
        g: 100,
        b: 100,
        primitive_marker: :solid
      }
    when @OUTCOMES[:bad]
      {
        x: 256,
        y: 256,
        w: GTK.args.grid.w - 512,
        h: GTK.args.grid.h - 512,
        r: 255,
        g: 100,
        b: 100,
        primitive_marker: :solid
      }
    when @OUTCOMES[:neutral]
      {
        x: 256,
        y: 256,
        w: GTK.args.grid.w - 512,
        h: GTK.args.grid.h - 512,
        r: 255,
        g: 100,
        b: 255,
        primitive_marker: :solid
      }
    when @OUTCOMES[:good]
      {
        x: 256,
        y: 256,
        w: GTK.args.grid.w - 512,
        h: GTK.args.grid.h - 512,
        r: 100,
        g: 255,
        b: 100,
        primitive_marker: :solid
      }
    end
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    bg_tile_index = 0.frame_index(24, 1.0.seconds, true)

    case layer_num
    when 0
      background_solid = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        r: 0,
        g: 0,
        b: 0,
        primitive_marker: :solid,
      }
      background = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        r: 50,
        g: 50,
        b: 50,
        a: 200,
        path:
          "sprites/background_frames/sketchybackground#{bg_tile_index + 1}.png"
      }

      l0 << [background_solid, background]
      return l0
    when 1
      l1 << []
      return l1
    when 2
      encounter_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 50,
        alignment_enum: 1,
        size_px: Math.sin(Kernel.tick_count * 0.08) * 4 + 40,
        r: 255,
        g: 255,
        b: 255,
        text: "Event",
        primitive_marker: :label
      }

      l2 << [encounter_label]
      return l2
    when 3
      l3 << [render_splash_art]
      return l3
    when 4
      msg_loc = Layout.rect(row: 10, col: 10, w: 4, h: 1).center
      msg = incremented_text?
      msg_lines = []
      wrapped_msg = String.wrapped_lines msg, 110
      msg_lines << wrapped_msg.map_with_index do |s, i|
        msg_loc.merge(
          text: "#{s}",
          anchor_x: 0.5,
          anchor_y: i,
          r: 255,
          g: 255,
          b: 255,
          size_px: 30,
          font: "fonts/eaglelake.ttf",
          primitive_marker: :label
        )
      end

      if @message_completed && @outcome == @OUTCOMES[:undetermined]
        @options_alpha = @options_alpha.lerp(255, 0.15)
        @options.each_with_index do |o, i|
          options_loc =
            Layout.rect(row: 2 + (i * 2), col: 10, w: 4, h: 1).center
          options_rect = Layout.rect(row: 1.5 + (i * 2), col: 6, w: 12, h: 1.5)

          @options[i]["rect"] = options_rect

          options_background = {
            x: options_rect[:x],
            y: options_rect[:y],
            w: options_rect[:w],
            h: options_rect[:h],
            primitive_marker: :solid,
            r: 0,
            g: 0,
            b: 0,
            a: @options_alpha / 2
          }

          options_text = o["text"]
          options_lines = []
          wrapped_options = String.wrapped_lines options_text, 50
          options_lines << wrapped_options.map_with_index do |s, i|
            options_loc.merge(
              text: "#{s}",
              anchor_x: 0.5,
              anchor_y: i,
              r: 255,
              g: 255,
              b: 255,
              a: @options_alpha,
              size_px: 22,
              font: "fonts/eaglelake.ttf",
              primitive_marker: :label
            )
          end

          l4 << [options_background, options_lines]
        end
      end

      click_prompt_label = {
        x: GTK.args.grid.w / 2,
        y: 50,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: 20,
        font: "fonts/eaglelake.ttf",
        text: "Click to Continue...",
        r: 255,
        g: 255,
        b: 255,
        primitive_marker: :label
      }

      if @option_selected_tick && @result_message_completed
        l4 << click_prompt_label
      end

      l4 << [msg_lines]
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end
end
