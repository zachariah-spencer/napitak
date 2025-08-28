class AudioService
  attr :current_song
  def initialize()
    $AUDIO_SERVICE = self
    @playing_sounds = []
    @current_song = nil
    @sounds = {
      open_book: {
        input: "sounds/sfx/book/book_open.wav",
        gain: 0.25,
        pitch: 1.0
      },
      close_book: {
        input: "sounds/sfx/book/book_close.wav",
        gain: 0.25,
        pitch: 1.0
      },
      get_fresh_ingredient: {
        input: "sounds/sfx/get_fresh_ingredient.wav",
        gain: 0.4,
        pitch: 1.75
      },
      remove_ingredient: {
        input: "sounds/sfx/remove_ingredient.wav",
        gain: 0.08,
        pitch: 1.0
      },
      card_hover: {
        input: "sounds/sfx/card/SFX_Card5.wav",
        gain: 0.5
      },
      card_unhover: {
        input: "sounds/sfx/card/SFX_Card5.wav",
        gain: 0.2,
        pitch: 0.8
      },
      card_draw: {
        input: "sounds/sfx/card/SFX_Card4.wav"
      },
      cards_shuffle: {
        input: "sounds/sfx/card/SFX_Shuffle2.wav",
        gain: 0.7
      },
      select_card: {
        input: "sounds/sfx/select_card.wav",
        gain: 0.8,
        pitch: 2
      },
      unselect_card: {
        input: "sounds/sfx/unselect_card.wav",
        gain: 0.6,
        pitch: 1.25
      },
      brew_action: {
        input: "sounds/sfx/brew_action.wav",
        gain: 0.25,
        pitch: 1
      },
      brew_action_completed: {
        input: "sounds/sfx/brew_action_completed.wav",
        gain: 0.5,
        pitch: 1
      },
      encounter_selected: {
        input: "sounds/sfx/brew_action_completed.wav",
        gain: 0.75,
        pitch: 0.2
      },
      bag_insert: {
        input: "sounds/sfx/bag_insert.wav",
        gain: 0.4,
        pitch: 1.15
      },
      bag_remove: {
        input: "sounds/sfx/bag_remove.wav",
        gain: 0.3,
        pitch: 1.15
      },
      hover_ingredient_generator: {
        input: "sounds/sfx/hover_ingredient_generator.wav",
        gain: 0.3,
        pitch: 1.25
      },
      unhover_ingredient_generator: {
        input: "sounds/sfx/hover_ingredient_generator.wav",
        gain: 0.08,
        pitch: 1.15
      },
      card_grab: {
        input: "sounds/sfx/card/card_grab.wav",
        gain: 0.4,
        pitch: 1.0
      },
      button_press: {
        input: "sounds/sfx/button_press.wav",
        gain: 0.1
      },
      button_hover: {
        input: "sounds/sfx/button_hover.wav",
        gain: 0.25,
        pitch: 1.2
      },
      button_unhover: {
        input: "sounds/sfx/button_hover.wav",
        gain: 0.15
      },
      wolf_start: {
        input: "sounds/sfx/wolf_howl.wav",
        gain: 1.25,
        pitch: 1.25
      },
      wolf_attack: {
        input: "sounds/sfx/wolf_snarl.wav",
        gain: 0.2,
        pitch: 1.0
      },
      wolf_hurt: {
        input: "sounds/sfx/wolf_hurt.wav",
        gain: 0.5
      },
      wolf_death: {
        input: "sounds/sfx/wolf_death.wav",
        gain: 0.6
      },
      hit_impact: {
        input: "sounds/sfx/hit_impact.wav",
        gain: 0.8,
        pitch: 1.0
      },
      victory_fanfare: {
        input: "sounds/sfx/victory_fanfare.wav",
        gain: 0.1
      },
      defeat_fanfare: {
        input: "sounds/sfx/defeat_fanfare.wav",
        gain: 0.1
      },
      waterbeam_cast: {
        input: "sounds/sfx/waterbeamcast.wav",
        gain: 0.8
      },
      firelick_cast: {
        input: "sounds/sfx/firelickcast.wav",
        gain: 0.8
      },
      flee_fanfare: {
        input: "sounds/sfx/flee_fanfare.wav",
        gain: 0.4
      },
      upgrade_selected: {
        input: "sounds/sfx/blessing.wav",
        gain: 0.12
      },
      loot_grabbed: {
        input: "sounds/sfx/loot_grabbed.wav",
        gain: 0.2
      },
      potion_recharged: {
        input: "sounds/sfx/potion_recharge.ogg",
        gain: 0.2
      }
    }

    @songs = {
      alchemy_encounter: {
        input: "sounds/music/alchemy_encounter.mp3",
        looping: true,
        gain: 0.09
      },
      combat_encounter: {
        input: "sounds/music/combat_encounter.mp3",
        looping: true,
        gain: 0.09
      },
      map_encounter: {
        input: "sounds/music/map_encounter.wav",
        looping: true,
        gain: 0.09
      },
      loot_encounter: {
        input: "sounds/music/loot_encounter.mp3",
        looping: true,
        gain: 0.09
      }
    }
  end

  def play_song(song)
    return if @current_song == @songs[song].dup
    if !@current_song
      # GTK.args.audio[:bg_music] = @songs[song]
      GTK.args.audio[:bg_music] = @songs[song].dup
    else
      transition_songs(song)
    end
    @current_song = song
  end

  def stop_song
    #FIXME: Implement method here
    if GTK.args.audio[:bg_music]
      GTK.args.audio[:bg_music] = GTK.args.audio[:bg_music].dup
    end
    @current_song = nil
  end

  def transition_songs(next_song)
    # get the current bg music and create a new audio entry that represents the crossfade
    current_bg_music = GTK.args.audio[:bg_music]

    # cross fade audio entry
    # GTK.args.audio[:bg_music_fade] = {
    #   input:    current_bg_music[:input],
    #   looping:  true,
    #   gain:     current_bg_music[:gain],
    #   pitch:    current_bg_music[:pitch],
    #   paused:   false,
    #   playtime: current_bg_music[:playtime]
    # }

    if GTK.args.audio[:bg_music]
      GTK.args.audio[:bg_music_fade] = GTK.args.audio[:bg_music]
    end

    new_background_music = @songs[next_song].dup
    new_background_music[:gain] = 0.0

    # bg music audio entry
    GTK.args.audio[:bg_music] = new_background_music
  end

  def tick
    @playing_sounds.reject! do |psid|
      if GTK.args.audio.none? { |id, s| id == psid }
        $EVENT_BUS.publish(:sound_finished_playback, sound: psid)
      end
      GTK.args.audio.none? { |id, s| id == psid }
    end

    @current_song ? process_crossfades : process_fade_out
  end

  def process_fade_out
    if GTK.args.audio[:bg_music] && GTK.args.audio[:bg_music].gain > 0.0
      # decrease by 1% every frame
      GTK.args.audio[:bg_music].gain -= 0.002
      # delete audio when it's at 0%
      GTK.args.audio[:bg_music] = nil if GTK.args.audio[:bg_music].gain <= 0.0
    end
  end

  def process_crossfades
    if GTK.args.audio[:bg_music] &&
         GTK.args.audio[:bg_music].gain < @songs[@current_song].gain
      # increase the gain 1% every tick until we are at 100%
      GTK.args.audio[:bg_music].gain += 0.007
      # clamp value to 1.0 max value
      GTK.args.audio[:bg_music].gain =
        @songs[@current_song].gain if GTK.args.audio[:bg_music].gain >
        @songs[@current_song].gain
    end

    # decrease the volume of cross fade bg music until it's 0.0, then delete it
    if GTK.args.audio[:bg_music_fade] &&
         GTK.args.audio[:bg_music_fade].gain > 0.0
      # decrease by 1% every frame
      GTK.args.audio[:bg_music_fade].gain -= 0.0008
      # delete audio when it's at 0%
      if GTK.args.audio[:bg_music_fade].gain <= 0.0
        # GTK.args.audio[:bg_music_fade] = nil
      end
    end
  end

  def play_sound(sound, rand_pitch: false)
    if !@sounds[sound]
      puts "ERROR: Sound not found in AudioService sounds hash."
      return
    end

    sound_id_string = sound.to_s
    sound_id_num = 0
    @playing_sounds.each do |s|
      sound_id_num += 1 if s.include?(sound_id_string)
    end

    sound_id_string += sound_id_num.to_s
    sound_id_hash = @sounds[sound].merge(id: sound_id_string)

    sound_id_hash[:pitch] = Numeric.rand(0.9..1.25) if rand_pitch

    @playing_sounds << sound_id_string
    GTK.args.audio[sound_id_string.to_sym] = sound_id_hash
  end
end
