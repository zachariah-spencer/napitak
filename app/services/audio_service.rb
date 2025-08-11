class AudioService
  def initialize()
    $AUDIO_SERVICE = self
    @playing_sounds = []
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
        gain: 0.3,
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
      }
    }
  end

  def play_sound(sound)
    if !@sounds[sound]
      raise "ERROR: Sound not found in AudioService sounds hash."
    end
    sound_id_string = sound.to_s
    sound_id_num = 0
    @playing_sounds.each do |s|
      sound_id_num += 1 if s.include?(sound_id_string)
    end
    sound_id_string += sound_id_num.to_s
    sound_id_hash = @sounds[sound].merge(id: sound_id_string)
    @playing_sounds << sound_id_string
    GTK.args.audio[sound_id_string.to_sym] = sound_id_hash
    puts "PLAYING SOUNDS: #{@playing_sounds}"
  end

  def tick
    @playing_sounds.reject! do |psid|
      GTK.args.audio.none? { |id, s| id == psid }
    end
  end
end
