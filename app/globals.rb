# frozen_string_literal: true

module GameData
  TRAITS = {
    damage: 0,
    restoration: 1,
    blight: 2,
    scorch: 3,
    frost: 4,
    ward: 5,
    mend: 6,
  }.freeze
  STATUS_TYPES = {
    "SCORCH" => 1,
    "BLIGHT" => 2,
    "FROST" => 3,
    "WARD" => 4,
    "RESTORATION" => 5
  }.freeze

  PIDS = {
    "p001" => {
      name: "Rock Potion",
      desc: "A basic potion that damages an enemy.",
      fc: 1,
      max_uses: 10,
      path: "sprites/circle/green.png",
      ingredients: {
        "i001" => 1,
        "i004" => 2
      },
      traits: [{ TRAITS[:damage] => 2 }, { TRAITS[:ward] => 6 }]
    },
    "p002" => {
      name: "Fiery Potion",
      desc: "A potion that catches an enemy on fire.",
      fc: 2,
      max_uses: 3,
      path: "sprites/circle/orange.png",
      ingredients: {
        "i001" => 1,
        "i003" => 2
      },
      traits: [TRAITS[:scorch] => 3]
    },
    "p003" => {
      name: "Ocean Potion",
      desc: "A potion that sprays water at an enemy damaging them.",
      fc: 1,
      max_uses: 2,
      path: "sprites/circle/blue.png",
      ingredients: {
        "i001" => 1,
        "i002" => 2
      },
      traits: [TRAITS[:restoration] => 2]
    },
    "p004" => {
      name: "Wind Potion",
      desc: "A potion that shoots air at an enemy damaging them.",
      fc: 2,
      max_uses: 4,
      path: "sprites/circle/indigo.png",
      ingredients: {
        "i001" => 1,
        "i005" => 2
      },
      traits: [{ TRAITS[:damage] => 4 }, { TRAITS[:mend] => 2 }]
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
