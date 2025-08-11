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
        gain: 0.25,
        pitch: 1.0
      },
      remove_ingredient: {
        input: "sounds/sfx/remove_ingredient.wav",
        gain: 0.25,
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
    }
  end

  def play_sound(sound)
    raise "ERROR: Sound not found in AudioService sounds hash." if !@sounds[sound]
    sound_id_string = sound.to_s
    sound_id_num = 0
    @playing_sounds.each { |s| sound_id_num += 1 if s.include?(sound_id_string) }
    sound_id_string += sound_id_num.to_s
    sound_id_hash = @sounds[sound].merge(id: sound_id_string)
    @playing_sounds << sound_id_string
    GTK.args.audio[sound_id_string.to_sym] = sound_id_hash
    puts "PLAYING SOUNDS: #{@playing_sounds}"
    
  end

  def tick
    puts @playing_sounds
    @playing_sounds.reject! { |psid| GTK.args.audio.none? { |id, s| id == psid } }
  end
end