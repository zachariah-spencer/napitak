$traits = {
    damage: 0,
    healing: 1,
    blight: 2,
}

$pids = {
    "p001" => {
    name: "Rock Potion",
    desc: "A basic potion that damages an enemy.",
    fc: 1,
    pow: 1,
    path: "sprites/circle/green.png",
    ingredients: [
        "i001", "i004", "i004",
    ],
    traits: [
        { 
            $traits[:damage] => 2,
        }
    ],
    },

    "p002" => {
    name: "Fiery Potion",
    desc: "A potion that catches an enemy on fire.",
    fc: 2,
    pow: 3,
    path: "sprites/circle/orange.png",
    ingredients: [
        "i001", "i003", "i003",
    ],
    traits: [
        $traits[:damage] => 3,
    ],
    },

    "p003" => {
    name: "Ocean Potion",
    desc: "A potion that sprays water at an enemy damaging them.",
    fc: 1,
    pow: 2,
    path: "sprites/circle/blue.png",
    ingredients: [
        "i001", "i002", "i002",
    ],
    traits: [
        $traits[:healing] => 2,
    ],
    },

    "p004" => {
    name: "Wind Potion",
    desc: "A potion that shoots air at an enemy damaging them.",
    fc: 2,
    pow: 4,
    path: "sprites/circle/indigo.png",
    ingredients: [
        "i001", "i005", "i005",
    ],
    traits: [
        $traits[:damage] => 4,
    ],
    },
}




$iids = {
    "i001" => {
    name: "Glass Bottle",
    path: "sprites/hexagon/white.png",
    },

    "i002" => {
    name: "Water",
    path: "sprites/hexagon/blue.png",
    },

    "i003" => {
    name: "Fire",
    path: "sprites/hexagon/orange.png",
    },

    "i004" => {
    name: "Earth",
    path: "sprites/hexagon/green.png",
    },

    "i005" => {
    name: "Air",
    path: "sprites/hexagon/indigo.png",
    },
}

$player = nil
$recipe_book = nil
$enemy = nil


def status_label(x, y, t, r, g, b, scale)
    $game.status_label(x, y, t, r, g, b, scale)
end