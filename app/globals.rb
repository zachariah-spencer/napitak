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
      traits: [
        { CARD_TRAITS[:damage] => { amount: 1, type: DAMAGE_TYPES[:heat] } }
      ]
    },
    "p002" => {
      name: "Combustible Potion",
      desc: "Explodes upon throwing causing destruction to nearby creatures.",
      fc: 2,
      max_uses: 2,
      path: "sprites/circle/orange.png",
      ingredients: {
        "i001" => 1,
        "i003" => 1,
        "i006" => 1
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 5, type: DAMAGE_TYPES[:force] } }
      ]
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
      traits: [
        { CARD_TRAITS[:damage] => { amount: 2, type: DAMAGE_TYPES[:force] } }
      ]
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
      traits: [{ CARD_TRAITS[:mend] => 3 }]
    },
    "p005" => {
      name: "Steamblast Potion",
      desc: "A hot blast of steam projects towards foes.",
      fc: 2,
      max_uses: 2,
      path: "sprites/circle/indigo.png",
      ingredients: {
        "i001" => 1,
        "i006" => 2
      },
      traits: [{ CARD_TRAITS[:scorch] => 3 }]
    },
    "p006" => {
      name: "Rock Potion",
      desc:
        "Liquid solidifies as it is thrown out of the bottle, slamming into foes.",
      fc: 0,
      max_uses: 5,
      path: "sprites/circle/green.png",
      ingredients: {
        "i001" => 1,
        "i004" => 2
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 1, type: DAMAGE_TYPES[:force] } }
      ]
    },
    "p007" => {
      name: "Wind Potion",
      desc: "A gust of wind bursts out of the bottle at foes.",
      fc: 2,
      max_uses: 3,
      path: "sprites/circle/white.png",
      ingredients: {
        "i001" => 1,
        "i005" => 2
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 1, type: DAMAGE_TYPES[:force] } },
        { CARD_TRAITS[:restoration] => 2 }
      ]
    },
    "p009" => {
      name: "Sandstone Potion",
      desc:
        "Reinforced dust globs out of the bottle forming a wall betwixt you and foes.",
      fc: 3,
      max_uses: 3,
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i004" => 1,
        "i007" => 1
      },
      traits: [{ CARD_TRAITS[:ward] => 5 }]
    },
    "p010" => {
      name: "Sandstorm Potion",
      desc:
        "Sand gusts out of the bottle creating a vortex of sand that swirls towards foes.",
      fc: 5,
      max_uses: 4,
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i004" => 1,
        "i007" => 1
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 5, type: DAMAGE_TYPES[:force] } },
        { CARD_TRAITS[:scorch] => 3 }
      ]
    },
    "p011" => {
      name: "Dune Potion",
      desc:
        "Sand gusts out of the bottle creating a vortex of sand that swirls towards foes.",
      fc: 4,
      max_uses: 1,
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i007" => 2
      },
      traits: [
        { CARD_TRAITS[:scorch] => 5 },
        { CARD_TRAITS[:mend] => 1 },
        { CARD_TRAITS[:ward] => 2 }
      ]
    },
    "p012" => {
      name: "Quicksand Potion",
      desc: "Creates a puddle of quicksand below enemies that envelop them.",
      fc: 1,
      max_uses: 6,
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i002" => 1,
        "i007" => 1
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 2, type: DAMAGE_TYPES[:force] } }
      ]
    },
    "p013" => {
      name: "Brickwall Potion",
      desc: "Creates a brickwall betwixt you and foes.",
      fc: 3,
      max_uses: 4,
      path: "sprites/circle/red.png",
      ingredients: {
        "i001" => 1,
        "i009" => 2
      },
      traits: [{ CARD_TRAITS[:ward] => 4 }]
    },
    "p014" => {
      name: "Lightning Potion",
      desc: "Strikes an arc of lightning at foes.",
      fc: 2,
      max_uses: 5,
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i008" => 2
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 2, type: DAMAGE_TYPES[:spark] } }
      ]
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
    },
    "i007" => {
      name: "Sand",
      path: "sprites/hexagon/yellow.png",
      base: false,
      ingredients: {
        "i004" => 1,
        "i005" => 1
      }
    },
    "i008" => {
      name: "Spark",
      path: "sprites/hexagon/yellow.png",
      base: false,
      ingredients: {
        "i003" => 1,
        "i005" => 1
      }
    },
    "i009" => {
      name: "Brick",
      path: "sprites/hexagon/red.png",
      base: false,
      ingredients: {
        "i003" => 1,
        "i004" => 1
      }
    },
    "i010" => {
      name: "Mist",
      path: "sprites/hexagon/blue.png",
      base: false,
      ingredients: {
        "i002" => 1,
        "i005" => 1
      }
    },
    "i011" => {
      name: "Mud",
      path: "sprites/hexagon/green.png",
      base: false,
      ingredients: {
        "i002" => 1,
        "i004" => 1
      }
    },
    "i012" => {
      name: "Glass",
      path: "sprites/hexagon/white.png",
      base: false,
      ingredients: {
        "i003" => 1,
        "i007" => 1
      }
    },
    "i013" => {
      name: "Electricity",
      path: "sprites/hexagon/yellow.png",
      base: false,
      ingredients: {
        "i002" => 1,
        "i008" => 1
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
      chance: 8
    },
    # basic enemy
    "wolf" => {
      name: "Wolf",
      path: "sprites/wolf.png",
      is_combat: true,
      chance: 4
    },
    # frost guy
    "wraith" => {
      name: "Wraith",
      path: "sprites/wraith.png",
      is_combat: true,
      chance: 1
    },
    # first boss encounter, uses
    "dracolisk" => {
      name: "Crystal Dracolisk",
      path: "sprites/triangle/equilateral/violet.png",
      is_combat: true,
      chance: 0
    },
    # ward earth guy
    "sentinel" => {
      name: "Ironroot Sentinel",
      path: "sprites/triangle/equilateral/green.png",
      is_combat: true,
      chance: 2
    },
    # fire guy
    "mawfiend" => {
      name: "Abyssal Mawfiend",
      path: "sprites/triangle/equilateral/orange.png",
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
