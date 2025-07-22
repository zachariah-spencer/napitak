# frozen_string_literal: true

module GameData
  CARD_TRAITS = {
    damage: 0,
    restoration: 1,
    blight: 2,
    scorch: 3,
    frost: 4,
    ward: 5,
    mend: 6
  }.freeze
  STATUS_TYPES = {
    SCORCH: 1,
    BLIGHT: 2,
    FROST: 3,
    WARD: 4,
    RESTORATION: 5
  }.freeze
  DAMAGE_TYPES = {
    force: 0,
    heat: 1,
    cold: 2,
    light: 3,
    dark: 4,
    spark: 5,
    disease: 6
  }.freeze
  DAMAGE_TYPE_NAMES = {
    DAMAGE_TYPES[:force] => "FORCE",
    DAMAGE_TYPES[:heat] => "HEAT",
    DAMAGE_TYPES[:cold] => "COLD",
    DAMAGE_TYPES[:light] => "LIGHT",
    DAMAGE_TYPES[:dark] => "DARK",
    DAMAGE_TYPES[:spark] => "SPARK",
    DAMAGE_TYPES[:disease] => "DISEASE"
  }.freeze
  STATUS_EFFECT_COLORS = {
    STATUS_TYPES[:SCORCH] => {
      r: 255,
      g: 100,
      b: 0,
      message: "SCORCHED"
    },
    STATUS_TYPES[:BLIGHT] => {
      r: 120,
      g: 150,
      b: 60,
      message: "BLIGHTED"
    },
    STATUS_TYPES[:FROST] => {
      r: 0,
      g: 255,
      b: 255,
      message: "FROSTED"
    },
    STATUS_TYPES[:WARD] => {
      r: 255,
      g: 255,
      b: 50,
      message: "WARDED"
    },
    STATUS_TYPES[:RESTORATION] => {
      r: 0,
      g: 255,
      b: 0,
      message: "RESTORED"
    }
  }.freeze
  DAMAGE_TYPE_COLORS = {
    DAMAGE_TYPES[:force] => {
      r: 255,
      g: 0,
      b: 0
    },
    DAMAGE_TYPES[:heat] => {
      r: 255,
      g: 100,
      b: 0
    },
    DAMAGE_TYPES[:cold] => {
      r: 0,
      g: 255,
      b: 255
    },
    DAMAGE_TYPES[:light] => {
      r: 255,
      g: 255,
      b: 255
    },
    DAMAGE_TYPES[:dark] => {
      r: 0,
      g: 0,
      b: 0
    },
    DAMAGE_TYPES[:spark] => {
      r: 255,
      g: 255,
      b: 0
    },
    DAMAGE_TYPES[:disease] => {
      r: 120,
      g: 150,
      b: 60
    }
  }.freeze
  DAMAGE_TYPE_SPRITES = {
    DAMAGE_TYPES[:force] => "sprites/square/indigo.png",
    DAMAGE_TYPES[:heat] => "sprites/square/orange.png",
    DAMAGE_TYPES[:cold] => "sprites/square/blue.png",
    DAMAGE_TYPES[:light] => "sprites/square/white.png",
    DAMAGE_TYPES[:dark] => "sprites/square/black.png",
    DAMAGE_TYPES[:spark] => "sprites/square/yellow.png",
    DAMAGE_TYPES[:disease] => "sprites/square/green.png"
  }.freeze

  def self.load_json(path)
    json = GTK.read_file(path)
    return {} unless json

    GTK.parse_json(json)
  end

  PIDS = load_json('data/potions.json')
  IIDS = load_json('data/ingredients.json')
  ENCOUNTERS = load_json('data/encounters.json')
  ANIMATIONS = load_json('data/animations.json')
end

$CARD_TRAITS = GameData::CARD_TRAITS
$STATUS_TYPES = GameData::STATUS_TYPES
$DAMAGE_TYPES = GameData::DAMAGE_TYPES
$DAMAGE_TYPE_NAMES = GameData::DAMAGE_TYPE_NAMES
$STATUS_EFFECT_COLORS = GameData::STATUS_EFFECT_COLORS
$DAMAGE_TYPE_COLORS = GameData::DAMAGE_TYPE_COLORS
$DAMAGE_TYPE_SPRITES = GameData::DAMAGE_TYPE_SPRITES
$PIDS = GameData::PIDS
$IIDS = GameData::IIDS
$ENCOUNTERS = GameData::ENCOUNTERS
$ANIMATIONS = GameData::ANIMATIONS
$TUTORIAL_INDEX = 0

$entity_ids = []
$player = nil
$recipe_book = nil
$enemy = nil
$tutorial_index = 0
