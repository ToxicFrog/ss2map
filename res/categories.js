function category(name, colour, show, description, types) {
  return {
    name: name,
    colour: colour,
    show: show,
    description: description,
    types: types,
  }
}

let CATEGORIES = [
  // Gear
  category("Equipment", "#ff8080", true,
    "Weapons, armour, implants, and software upgrades.",
    ["Object/Physical/Weapon", "Object/Physical/Goodies/Armor", "Object/Physical/Goodies/Implants"]),
  category("Software", "#ff0080", true,
    "Software upgrades and MFD games",
    ["Object/Physical/Goodies/Softs", "Object/Physical/Goodies/MFD Games"]),
  category("Keys", "#80ff80", true,
    "Keycards",
    ["Object/Physical/Keys"]),
  category("Audio Logs", "#80ff80", true,
    "The last words of the dead.",
    ["Object/Physical/Goodies/Audio Log"]),
  // Consumables
  category("Ammo", "#8080ff", true,
    "Food for your trusty guns.",
    ["Object/Physical/Goodies/Ammo",
     "Object/Physical/Functional/Worm Piles", "Object/Physical/Goodies/Beakers"]),
  category("Meds", "#00ffff", true,
    "Hypos, medkits, etc.",
    ["Object/Physical/Goodies/Patches"]),
  category("Tools", "#80ff80", true,
    "Batteries, ICE picks, etc.",
    ["Object/Physical/Devices"]),
  category("Chems", "#80ff80", true,
    "Research chamicals",
    ["Object/Physical/Goodies/Chemicals"]),
  category("Researchables", "#80ff80", true,
    "Organs and whatnot",
    ["Object/Physical/Goodies/Researchable"]),
  category("Nanites", "#80ff80", true,
    "Nanites",
    ["Object/Physical/Goodies/Nanites"]),
  category("Cyber Modules", "#80ff80", true,
    "yum",
    ["Object/Physical/Goodies/EXP Cookies"]),
  category("Other Goodies", "#00ffff", true,
    "Anything not in the above categories.",
    ["Object/Physical/Goodies",
     "Object/Physical/Treasure"]),
  // Interactables
  category("Containers", "#A0A0A0", true,
     "Things that can contain other things.",
     ["Object/Physical/Corpses", "Object/Physical/Functional/Usable Containers",
      "Object/Physical/Container"]),
  category("Critters", "#ff0000", false,
    "Living things that want you dead.",
    ["Object/Physical/Monsters", "Object/Physical/Monster Accessories",
      "Object/Physical/Creature"]),
  category("Functional", "#ffff00", true,
    "Interactable objects like computers, buttons, and card readers.",
    ["Object/Physical/Functional"]),
  category("Doors", "#A0A000", true,
    "They open. They shut.",
    ["Object/Physical/Terrain/Doors",
     "Object/Physical/TerrainLike/Door"]),
  // Terrain
  category("Plot Decorations", "#0080ff", false,
    "Plot-related miscellaneous terrain and some items.",
    ["Object/Physical/Plot Items"]),
  category("Decorative", "#ffffff", false,
    "Decorative, mostly non-interactable objects.",
    ["Object/Physical/Decorative", "Object/Physical/Lights", "Object/Physical/Terrain",
     "Object/Physical/Furniture"]),
  category("Traps and Triggers", "#ffffff", false,
    "Event triggers, level behaviour contraptions, etc.",
    ["Object/Traps", "Object/Marker"]),
  category("Miscellaneous", "#ffffff", false,
    "Anything not in the above categories.",
    ["Object"]),
  // Not categorized:
  // SFX, Schema, Voice, Physical/Special, Physical/Network Avatar, Complex,
  // The Player, MotArchetypes, Projectile, Particle, HUD Objects, Missing
]

function initCategories() {
  let div = document.getElementById("layercontrols")
  let rows = [];
  for (let i in CATEGORIES) {
    let cat = CATEGORIES[i]
    cat.index = i
    rows.push('<label title="'
      + cat.description
      + '"><input type="checkbox"'
      + (cat.show ? ' checked' : '')
      + ' onchange="updateLayers();"/>'
      + cat.name
      + '</label><br/>\n')
  }
  div.innerHTML = rows.join('\n')
}

function getCategoryForType(type) {
  for (let i in CATEGORIES) {
    let cat = CATEGORIES[i]
    for (let j in cat.types) {
      // console.log(i, cat.name, '['+cat.types[j]+']', '['+type+']', type.startsWith(cat.types[j]))
      if (type.toLowerCase().startsWith(cat.types[j].toLowerCase())) {
        return cat
      }
    }
  }
}
