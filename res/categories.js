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
  category("Weapons", "#ff0000", true,
    "Tools of violence.",
    ["Object/Physical/Weapon"]),
  category("Goodies", "#00ffff", true,
    "Meds, ammo, audio logs, nanites, keys, etc.",
    ["Object/Physical/Goodies", "Object/Physical/Keys"]),
  category("Critters", "#ff8080", false,
    "Living things that want you dead.",
    ["Object/Physical/Monsters", "Object/Physical/Monster Accessories"]),
  category("Containers", "#A0A0A0", true,
    "Things that can contain other things.",
    ["Object/Physical/Corpses", "Object/Physical/Functional/Usable Containers"]),
  category("Plot Items", "#0080ff", false,
    "Plot-related miscellaneous terrain and some items.",
    ["Object/Physical/Plot Items"]),
  category("Functional", "#ffff00", true,
    "Interactable objects like computers, buttons, and card readers.",
    ["Object/Physical/Functional"]),
  category("Doors", "#A0A000", true,
    "They open. They shut.",
    ["Object/Physical/Terrain/Doors"]),
  category("Decorative", "#ffffff", false,
    "Decorative, mostly non-interactable objects.",
    ["Object/Physical/Decorative", "Object/Physical/Lights", "Object/Physical/Terrain"]),
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
      if (type.startsWith(cat.types[j])) {
        return cat
      }
    }
  }
}
