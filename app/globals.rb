# frozen_string_literal: true

module GameData
  FONT = "fonts/amarante.ttf"
  CARD_TRAITS = {
    damage: 0,
    restoration: 1,
    blight: 2,
    scorch: 3,
    frost: 4,
    ward: 5,
    mend: 6,
    channel: 7,
    blind: 8
  }.freeze
  STATUS_TYPES = {
    SCORCH: 1,
    BLIGHT: 2,
    FROST: 3,
    WARD: 4,
    RESTORATION: 5,
    BLIND: 6
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
    },
    STATUS_TYPES[:BLIND] => {
      r: 150,
      g: 150,
      b: 150,
      message: "SHROUDED"
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
      primary_base_ingredient_id: "i003",
      path: "sprites/flamelickbottle.png",
      ingredients: {
        "i001" => 1,
        "i003" => 2
      },
      cast_animation: {
        id: "p001",
        path: "sprites/flamelickcast-sheet-19.png",
        count: 19,
        hold_for: 4,
        impact_frame: 8,
        repeat: false,
      },
      cast_sfx: :firelick_cast,
      finisher_trait: { CARD_TRAITS[:ward] => 5 },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 5, type: DAMAGE_TYPES[:heat] } },
      ],
    },
    "p002" => {
      name: "Combustible Potion",
      desc: "Explodes upon throwing causing destruction to nearby creatures.",
      fc: 4,
      max_uses: 2,
      primary_base_ingredient_id: "i003",
      path: "sprites/combustiblebottle.png",
      cast_animation: {
        id: "p002",
        path: "sprites/combustiblecast-sheet-256x720-25.png",
        count: 25,
        hold_for: 4,
        impact_frame: 13,
        repeat: false,
      },
      cast_sfx: :combustiblecast,
      ingredients: {
        "i001" => 1,
        "i003" => 1,
        "i006" => 1
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 15, type: DAMAGE_TYPES[:heat] } }
      ],
    },
    "p003" => {
      name: "Waterbeam Potion",
      desc: "Sprays water at high pressure at foes.",
      fc: 0,
      max_uses: 5,
      primary_base_ingredient_id: "i002",
      path: "sprites/waterbeambottle.png",
      ingredients: {
        "i001" => 1,
        "i002" => 2
      },
      cast_animation: {
        id: "p003",
        path: "sprites/waterbeamcast-sheet-23.png",
        count: 23,
        hold_for: 4,
        impact_frame:9,
        repeat: false,
      },
      cast_sfx: :waterbeam_cast,
      traits: [
        { CARD_TRAITS[:damage] => { amount: 2, type: DAMAGE_TYPES[:cold] } }
      ]
    },
    "p004" => {
      name: "Cloudy Potion",
      desc: "A sip of the clouds lifts ones' spirits and heals them.",
      fc: 2,
      max_uses: 3,
      primary_base_ingredient_id: "i002",
      path: "sprites/circle/blue.png",
      ingredients: {
        "i001" => 1,
        "i002" => 1,
        "i006" => 1
      },
      traits: [{ CARD_TRAITS[:mend] => 10 }]
    },
    "p005" => {
      name: "Steamblast Potion",
      desc: "A hot blast of steam projects towards foes.",
      fc: 3,
      max_uses: 2,
      primary_base_ingredient_id: "i002",
      path: "sprites/circle/indigo.png",
      ingredients: {
        "i001" => 1,
        "i006" => 2
      },
      traits: [
        { CARD_TRAITS[:scorch] => 6 },
        { CARD_TRAITS[:damage] => { amount: 4, type: DAMAGE_TYPES[:heat] } }
    ]
    },
    "p006" => {
      name: "Rock Potion",
      desc:
        "Liquid solidifies as it is thrown out of the bottle, slamming into foes.",
      fc: 0,
      max_uses: 5,
      primary_base_ingredient_id: "i004",
      path: "sprites/circle/green.png",
      ingredients: {
        "i001" => 1,
        "i004" => 2
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 1, type: DAMAGE_TYPES[:force] } },
        { CARD_TRAITS[:ward] => 1 }
      ]
    },
    "p007" => {
      name: "Wind Potion",
      desc: "A gust of wind bursts out of the bottle at foes.",
      fc: 3,
      max_uses: 3,
      primary_base_ingredient_id: "i005",
      path: "sprites/circle/white.png",
      ingredients: {
        "i001" => 1,
        "i005" => 2
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 7, type: DAMAGE_TYPES[:force] } },
        { CARD_TRAITS[:restoration] => 5 }
      ]
    },
    "p009" => {
      name: "Sandstone Potion",
      desc:
        "Reinforced dust globs out of the bottle forming a wall betwixt you and foes.",
      fc: 5,
      max_uses: 3,
      primary_base_ingredient_id: "i004",
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i004" => 1,
        "i007" => 1
      },
      traits: [{ CARD_TRAITS[:ward] => 15 }]
    },
    "p010" => {
      name: "Sandstorm Potion",
      desc:
        "Sand gusts out of the bottle creating a vortex of sand that swirls towards foes.",
      fc: 5,
      max_uses: 4,
      primary_base_ingredient_id: "i005",
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i005" => 1,
        "i007" => 1
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 8, type: DAMAGE_TYPES[:force] } },
        { CARD_TRAITS[:scorch] => 5 }
      ]
    },
    "p011" => {
      name: "Dune Potion",
      desc:
        "A desert dune blossoms from the bottle enveloping foes.",
      fc: 4,
      max_uses: 1,
      primary_base_ingredient_id: "i004",
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i007" => 2
      },
      traits: [
        { CARD_TRAITS[:scorch] => 10 },
        { CARD_TRAITS[:mend] => 5 },
        { CARD_TRAITS[:ward] => 5 }
      ]
    },
    "p012" => {
      name: "Quicksand Potion",
      desc: "Creates a puddle of quicksand below enemies that envelop them.",
      fc: 3,
      max_uses: 6,
      primary_base_ingredient_id: "i004",
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i002" => 1,
        "i007" => 1
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 8, type: DAMAGE_TYPES[:force] } }
      ]
    },
    "p013" => {
      name: "Brickwall Potion",
      desc: "Creates a brickwall betwixt you and foes.",
      fc: 6,
      max_uses: 4,
      primary_base_ingredient_id: "i004",
      path: "sprites/circle/red.png",
      ingredients: {
        "i001" => 1,
        "i009" => 2
      },
      traits: [{ CARD_TRAITS[:ward] => 20 }]
    },
    "p014" => {
      name: "Lightning Potion",
      desc: "Strikes an arc of lightning at foes.",
      fc: 2,
      max_uses: 4,
      primary_base_ingredient_id: "i005",
      path: "sprites/circle/yellow.png",
      ingredients: {
        "i001" => 1,
        "i008" => 2
      },
      traits: [
        { CARD_TRAITS[:damage] => { amount: 6, type: DAMAGE_TYPES[:spark] } }
      ]
    }
  }.freeze
  IIDS = {
    # BASEs
    "i001" => {
      name: "Bottle",
      path: "sprites/bottle.png",
      base: true
    },
    "i002" => {
      name: "Water",
      path: "sprites/water.png",
      base: true
    },
    "i003" => {
      name: "Fire",
      path: "sprites/fire.png",
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
      path: "sprites/steam.png",
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
  SHOP_ITEMS = {
    "s001" => {
      name: "Focus Shard",
      path: "sprites/hexagon/blue.png"
    },
    "s002" => {
      name: "HP Shard",
      path: "sprites/hexagon/red.png"
    }
  }.merge(IIDS)
  REWARD_ITEMS = SHOP_ITEMS.select { |k, v| k[0] == "s" || v[:base] }
  ENCOUNTERS = {
    "alchemy_lab" => {
      name: "Laboratory",
      path: "sprites/laboratory_icon-sheet-512x512-3.png",
      is_combat: false,
      chance: 0
    },
    "alchemy_table" => {
      name: "Brew Bench",
      path: "sprites/brewbench_icon-sheet-512x512-3.png",
      is_combat: false,
      chance: 8
    },
    "rp_encounter" => {
      name: "Event",
      path: "sprites/event_icon-sheet-512x512-3.png",
      is_combat: false,
      chance: 4
    },
    "shop" => {
      name: "Trader",
      path: "sprites/trader_icon-sheet-512x512-3.png",
      is_combat: false,
      chance: 2
    },
    # basic enemy
    "wolf" => {
      name: "Wolf",
      path: "sprites/wolf-sheet-3.png",
      is_combat: true,
      chance: 15
    },
    # basic enemy
    "bat" => {
      name: "Bat",
      path: "sprites/bat_idle_512x512-sheet-6.png",
      is_combat: true,
      chance: 15
    },
    # frost guy
    "wraith" => {
      name: "Wraith",
      path: "sprites/wraith.png",
      is_combat: true,
      chance: 3
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
  ENEMY_ANIMATIONS = {
    wolf: {
      idle: {
        path: "sprites/wolf-sheet-3.png",
        count: 3,
        hold_for: 30,
        repeat: true,
      },
      hurt: {
        path: "sprites/wolf_death-sheet-15.png",
        count: 4,
        hold_for: 5,
        repeat: false,
      },
      death: {
        path: "sprites/wolf_death-sheet-15.png",
        count: 15,
        hold_for: 5,
        repeat: false
      },
      attacks: {
        basic: {
          path: "sprites/wolf_attack1-sheet-4.png",
          count: 4,
          hold_for: 10,
          impact_frame: 1,
          repeat: false,
          sfx: :wolf_attack1
        },
        special: {
          path: "sprites/wolf_attack2-sheet-4.png",
          count: 4,
          hold_for: 10,
          impact_frame: 1,
          repeat: false,
          sfx: :wolf_attack1
        },
        apex:  {
          path: "sprites/wolf_attack3-sheet-14.png",
          count: 14,
          hold_for: 10,
          impact_frame: 10,
          repeat: false,
          sfx: :wolf_attack3
        },
      },
    },
    bat: {
      idle: {
        path: "sprites/bat_idle_512x512-sheet-6.png",
        count: 6,
        hold_for: 8,
        repeat: true,
      },
      hurt: {
        path: "sprites/bat_hurt_512x512_sheet_17.png",
        count: 17,
        hold_for: 5,
        repeat: false,
      },
      death: {
        path: "sprites/bat_death_512x512_sheet_9.png",
        count: 9,
        hold_for: 8,
        repeat: false
      },
      attacks: {
        basic: {
          path: "sprites/bat_attack_1_512x512_sheet_9.png",
          count: 9,
          hold_for: 6,
          impact_frame: 5,
          repeat: false,
          sfx: :bat_attack_1
        },
        special: {
          path: "sprites/bat_attack_2_512x512_sheet_13.png",
          count: 13,
          hold_for: 8,
          impact_frame: 5,
          repeat: false,
          sfx: :bat_attack_2
        },
      },
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
$ENEMY_ANIMATIONS = GameData::ENEMY_ANIMATIONS
$SHOP_ITEMS = GameData::SHOP_ITEMS
$REWARD_ITEMS = GameData::REWARD_ITEMS
$TUTORIAL_INDEX = 0
$FONT = GameData::FONT

$entity_ids = []
$player = nil
$recipe_book = nil
$enemy = nil
$tutorial_index = 0
