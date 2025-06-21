# frozen_string_literal: true

module GameData
  TRAITS = {
    damage: 0,
    restoration: 1,
    blight: 2,
    scorch: 3,
    frost: 4,
    ward: 5,
    mend: 6
  }.freeze
  STATUS_TYPES = {
    #FIXME: Refactor to symbols over strings eventually, idk why I did this like this?????
    "SCORCH" => 1,
    "BLIGHT" => 2,
    "FROST" => 3,
    "WARD" => 4,
    "RESTORATION" => 5
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
  STATUS_EFFECT_COLORS = {
    STATUS_TYPES["SCORCH"] => {
      r: 0,
      g: 0,
      b: 0
    },
    STATUS_TYPES["BLIGHT"] => {
      r: 0,
      g: 0,
      b: 0
    },
    STATUS_TYPES["FROST"] => {
      r: 0,
      g: 0,
      b: 0
    },
    STATUS_TYPES["WARD"] => {
      r: 0,
      g: 0,
      b: 0
    },
    STATUS_TYPES["RESTORATION"] => {
      r: 0,
      g: 0,
      b: 0
    }
  }.freeze
  DAMAGE_TYPE_COLORS = {
    DAMAGE_TYPES[:force] => {
      r: 0,
      g: 0,
      b: 0
    },
    DAMAGE_TYPES[:heat] => {
      r: 0,
      g: 0,
      b: 0
    },
    DAMAGE_TYPES[:cold] => {
      r: 0,
      g: 0,
      b: 0
    },
    DAMAGE_TYPES[:light] => {
      r: 0,
      g: 0,
      b: 0
    },
    DAMAGE_TYPES[:dark] => {
      r: 0,
      g: 0,
      b: 0
    },
    DAMAGE_TYPES[:spark] => {
      r: 0,
      g: 0,
      b: 0
    },
    DAMAGE_TYPES[:disease] => {
      r: 0,
      g: 0,
      b: 0
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
  PIDS = {
    "p001" => {
      name: "Flamelick Potion",
      desc: "Flames leap from the bottle at foes.",
      fc: 1,
      max_uses: 5,
      path: "sprites/circle/orange.png",
      ingredients: {
        "i001" => 1,
        "i003" => 2
      },
      traits: [{ TRAITS[:damage] => { amount: 1, type: DAMAGE_TYPES[:heat] } }]
    },
    "p002" => {
      name: "Combustible Potion",
      desc: "Explodes upon throwing causing destruction to nearby creatures.",
      fc: 2,
      max_uses: 1,
      path: "sprites/circle/orange.png",
      ingredients: {
        "i001" => 1,
        "i003" => 1,
        "i006" => 1
      },
      traits: [{ TRAITS[:damage] => { amount: 6, type: DAMAGE_TYPES[:force] } }]
    },
    "p003" => {
      name: "Waterbeam Potion",
      desc: "Sprays water at high pressure at foes.",
      fc: 2,
      max_uses: 5,
      path: "sprites/circle/blue.png",
      ingredients: {
        "i001" => 1,
        "i002" => 2
      },
      traits: [{ TRAITS[:damage] => { amount: 2, type: DAMAGE_TYPES[:force] } }]
    },
    "p004" => {
      name: "Cloudy Potion",
      desc: "A sip of the clouds lifts ones' spirits and heals them.",
      fc: 2,
      max_uses: 3,
      path: "sprites/circle/blue.png",
      ingredients: {
        "i001" => 1,
        "i002" => 1,
        "i006" => 1
      },
      traits: [{ TRAITS[:mend] => 3 }]
    },
    "p005" => {
      name: "Steamblast Potion",
      desc: "A hot blast of steam projects towards foes.",
      fc: 2,
      max_uses: 2,
      path: "sprites/circle/blue.png",
      ingredients: {
        "i001" => 1,
        "i006" => 2
      },
      traits: [{ TRAITS[:scorch] => 3 }]
    }
  }.freeze
  IIDS = {
    # BASEs
    "i001" => {
      name: "Bottle",
      path: "sprites/hexagon/white.png",
      base: true
    },
    "i002" => {
      name: "Water",
      path: "sprites/hexagon/blue.png",
      base: true
    },
    "i003" => {
      name: "Fire",
      path: "sprites/hexagon/orange.png",
      base: true
    },
    "i004" => {
      name: "Earth",
      path: "sprites/hexagon/green.png",
      base: true
    },
    "i005" => {
      name: "Air",
      path: "sprites/hexagon/indigo.png",
      base: true
    },
    # T1s
    "i006" => {
      name: "Steam",
      path: "sprites/hexagon/indigo.png",
      base: false,
      ingredients: {
        "i002" => 1,
        "i003" => 1
      }
    }
  }.freeze
  ENCOUNTERS = {
    "alchemy_lab" => {
      name: "Laboratory",
      path: "sprites/triangle/equilateral/indigo.png",
      is_combat: false,
      chance: 0
    },
    "alchemy_table" => {
      name: "Alchemy Workbench",
      path: "sprites/triangle/equilateral/yellow.png",
      is_combat: false,
      chance: 10
    },
    "wolf" => {
      name: "Wolf",
      path: "sprites/wolf.png",
      is_combat: true,
      chance: 5
    },
    "ghost" => {
      name: "Ghost",
      path: "sprites/ghost.png",
      is_combat: true,
      chance: 2
    }
  }.freeze
  ANIMATIONS = {
    "a001" => {
      rect: {
        x: GTK.args.grid.w / 2 - 100,
        y: GTK.args.grid.h / 2 - 100,
        w: 200,
        h: 200
      },
      frames: %w[
        sprites/misc/explosion-0.png
        sprites/misc/explosion-1.png
        sprites/misc/explosion-2.png
        sprites/misc/explosion-3.png
        sprites/misc/explosion-4.png
        sprites/misc/explosion-5.png
        sprites/misc/explosion-6.png
      ],
      frame_length: 5,
      particle_frames: {
      }
    },
    "a002" => {
      rect: {
        x: GTK.args.grid.w / 2 - 100,
        y: GTK.args.grid.h / 2 - 100,
        w: 200,
        h: 200
      },
      frames: %w[
        sprites/misc/explosion-0.png
        sprites/misc/explosion-1.png
        sprites/misc/explosion-2.png
        sprites/misc/explosion-3.png
        sprites/misc/explosion-4.png
        sprites/misc/explosion-5.png
        sprites/misc/explosion-6.png
      ],
      frame_length: 5,
      particle_frames: {
      }
    },
    "a003" => {
      rect: {
        x: GTK.args.grid.w / 2 - 100,
        y: GTK.args.grid.h / 2 - 100,
        w: 200,
        h: 200
      },
      frames: %w[
        sprites/misc/explosion-0.png
        sprites/misc/explosion-1.png
        sprites/misc/explosion-2.png
        sprites/misc/explosion-3.png
        sprites/misc/explosion-4.png
        sprites/misc/explosion-5.png
        sprites/misc/explosion-6.png
      ],
      frame_length: 5,
      particle_frames: {
      }
    }
  }.freeze
end

$traits = GameData::TRAITS
$STATUS_TYPES = GameData::STATUS_TYPES
$DAMAGE_TYPES = GameData::DAMAGE_TYPES
$STATUS_EFFECT_COLORS = GameData::STATUS_EFFECT_COLORS
$DAMAGE_TYPE_COLORS = GameData::DAMAGE_TYPE_COLORS
$DAMAGE_TYPE_SPRITES = GameData::DAMAGE_TYPE_SPRITES
$pids = GameData::PIDS
$iids = GameData::IIDS
$encounters = GameData::ENCOUNTERS
$animations = GameData::ANIMATIONS

$entity_ids = []
$player = nil
$recipe_book = nil
$enemy = nil
$files = nil
$encounter_manager = nil
$tutorials = true
