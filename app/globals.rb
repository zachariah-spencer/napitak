$traits = { damage: 0, healing: 1, blight: 2 }

$pids = {
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
    traits: [{ $traits[:damage] => 2 }]
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
    traits: [$traits[:damage] => 3]
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
    traits: [$traits[:healing] => 2]
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
    traits: [$traits[:damage] => 20]
  }
}

$iids = {
  # T0
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
  # T1
  "i006" => {
    name: "Steam",
    path: "sprites/hexagon/indigo.png",
    base: false,
    ingredients: {
      "i002" => 1,
      "i003" => 1
    }
  }
}

$encounters = {
  "alchemy_lab" => {
    name: "Laboratory",
    path: "sprites/triangle/equilateral/indigo.png",
    chance: 0
  },
  "combat" => {
    name: "Combat",
    path: "sprites/triangle/equilateral/red.png",
    chance: 1
  },
  "alchemy_table" => {
    name: "Alchemy Workbench",
    path: "sprites/triangle/equilateral/yellow.png",
    chance: 1
  },
}

def craftable_ingredients?
  @ingredient_defs.select { |id, ing| !ing.base }
end

def is_potion(item_id)
  item_id[0] == "p"
end

$player = nil
$recipe_book = nil
$enemy = nil
$encounter_manager = nil
$tutorials = true

def status_label(x, y, t, r, g, b, scale)
  $game.status_label(x, y, t, r, g, b, scale)
end

def gen_new_card(id = nil, is_reward: false)
  all_ids = $pids.keys + $iids.keys

  if id == nil
    #id = all_ids.sample
    id = $iids.keys.sample
    while id == "i001"
      #id = all_ids.sample
      id = $iids.keys.sample
    end
  end

  name = nil
  fc = 0
  img = nil

  new_ent_id = get_rand_id

  if is_reward
    name = $iids[id].name
    img = $iids[id].path
    new_card = IngredientRewardCard.new(id, new_ent_id, name, fc, img)
  else
    if id[0] == "p"
      name = $pids[id].name
      fc = $pids[id].fc
      img = $pids[id].path
      max_uses = $pids[id].max_uses
      new_card = PotionCard.new(id, new_ent_id, name, fc, img, max_uses)
    else
      name = $iids[id].name
      img = $iids[id].path
      new_card = IngredientCard.new(id, new_ent_id, name, fc, img)
    end
  end

  new_card
end

def get_rand_id
  ingredient_ids = $player.ingredients.all_cards.map(&:entity_id)
  potion_ids = $player.potions.all_cards.map(&:entity_id)
  all_entity_ids = ingredient_ids + potion_ids
  new_id = Numeric.rand(1..50_000)

  new_id = Numeric.rand(1..50_000) while all_entity_ids.include?(new_id)

  return new_id
end
