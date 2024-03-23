-- Select the gamesys to use. This contains object name and type information and
-- it's important to use one that matches the maps you're loading.
-- It can be overriden on the command line with --gamesys, unlike the other
-- settings in this file.

--setgamesys 'shock.gam'  -- Vanilla SS2
setgamesys 'shockscp.gam'  -- Shock Community Patch

-- Define item categories. You can add as many as you want.
-- Items will be checked against these categories in the same order they appear
-- in this file, with the first match winning, so more specific categories should
-- go before more general ones.
-- TODO: longest-match rather than first-match would let us decouple order from
-- matching semantics and instead order categories based entirely on what works
-- best in the UI.

-- The top-level name, 'Equipment', is what will be show up in the category filter
-- panel in the map viewer.
defcategory 'Equipment' {
  -- Colour to use for icons on the map. Required.
  colour = '#ff8080';
  -- Whether this category should be visible on the map by default, or hidden
  -- until the user turns it on. Optional, default false.
  visible = true;
  -- If present, this will be visibleed in a tooltip on mouseover. Optional
  -- human-friendly description of what this category contains.
  info = 'Weapons, armour, implants, and software upgrades.';
  -- Fully qualified type names that should be included in this category. Items
  -- are matched with this category if their FQTN starts with one of these.
  -- These are also visibleed in the tooltip after the info, one per line.
  -- Required. Case insensitive.
  types = {
    'Object/Physical/Weapon',
    'Object/Physical/Goodies/Armor',
    'Object/Physical/Goodies/Implants',
  };
}

defcategory 'Software' {
  colour = '#ff0080';
  visible = true;
  info = 'Software upgrades and MFD games';
  types = {
    'Object/Physical/Goodies/Softs',
    'Object/Physical/Goodies/MFD Games',
  };
}

defcategory 'Keys' {
  colour = '#80ff80';
  visible = true;
  info = 'Keycards';
  types = {
    'Object/Physical/Keys',
  };
}

defcategory 'Audio Logs' {
  colour = '#80ff80';
  visible = true;
  info = 'The last words of the dead.';
  types = {
    'Object/Physical/Goodies/Audio Log',
  };
}

defcategory 'Ammo' {
  colour = '#8080ff';
  visible = true;
  info = 'Food for your trusty guns.';
  types = {
    'Object/Physical/Goodies/Ammo',
    'Object/Physical/Functional/Worm Piles',
    'Object/Physical/Goodies/Beakers',
  };
}

defcategory 'Meds' {
  colour = '#00ffff';
  visible = true;
  info = 'Hypos, medkits, etc.';
  types = {
    'Object/Physical/Goodies/Patches',
  };
}

defcategory 'Tools' {
  colour = '#80ff80';
  visible = true;
  info = 'Batteries, ICE picks, etc.';
  types = {
    'Object/Physical/Devices',
  };
}

defcategory 'Chems' {
  colour = '#80ff80';
  visible = true;
  info = 'Research chamicals';
  types = {
    'Object/Physical/Goodies/Chemicals',
  };
}

defcategory 'Researchables' {
  colour = '#80ff80';
  visible = true;
  info = 'Organs and whatnot';
  types = {
    'Object/Physical/Goodies/Researchable',
  };
}

defcategory 'Nanites' {
  colour = '#80ff80';
  visible = true;
  info = 'Nanites';
  types = {
    'Object/Physical/Goodies/Nanites',
  };
}

defcategory 'Cyber Modules' {
  colour = '#80ff80';
  visible = true;
  info = 'yum';
  types = {
    'Object/Physical/Goodies/EXP Cookies',
  };
}

defcategory 'Other Goodies' {
  colour = '#00ffff';
  visible = true;
  info = 'Anything not in the above categories.';
  types = {
    'Object/Physical/Goodies',
  };
}

defcategory 'Containers' {
  colour = '#A0A0A0';
  visible = true;
  info = 'Things that can contain other things.';
  types = {
    'Object/Physical/Corpses',
    'Object/Physical/Functional/Usable Containers',
    'Object/Physical/Container',
  };
}

defcategory 'Critters' {
  colour = '#ff0000';
  info = 'Living things that want you dead.';
  types = {
    'Object/Physical/Monsters',
    'Object/Physical/Monster Accessories',
  };
}

defcategory 'Switches' {
  colour = '#00ff00';
  visible = true;
  info = 'Interactable objects like computers, buttons, and card readers.';
  types = {
    'Object/Physical/Functional/Controllers',
  };
}

defcategory 'Doors' {
  colour = '#A0A000';
  visible = true;
  info = 'They open. They shut.';
  types = {
    'Object/Physical/Terrain/Doors',
  };
}

defcategory 'Functional' {
  colour = '#ffa020';
  visible = true;
  info = 'Other interactable objects, like recharge stations and explosives.';
  types = {
    'Object/Physical/Functional',
  };
}

defcategory 'Plot Decorations' {
  colour = '#0080ff';
  info = "Plot-related miscellaneous terrain and some items.";
  types = {
    'Object/Physical/Plot Items',
  }
}

defcategory 'Decorative' {
  colour = '#ffffff';
  info = "Plot-related miscellaneous terrain and some items.";
  types = {
    'Object/Physical/Decorative',
    'Object/Physical/Lights',
    'Object/Physical/Terrain',
    'Object/Physical/Furniture',
  }
}

defcategory 'Traps and Triggers' {
  colour = '#ffffff';
  info = 'Event triggers, level behaviour contraptions, etc.';
  types = {
    'Object/Traps',
    'Object/Marker',
  }
}

defcategory 'SFX' {
  colour = '#FFFFFF';
  types = {
    'Object/SFX',
  }
}

defcategory 'Other' {
  colour = '#ffffff';
  info = 'Anything not in the above categories.';
  types = {
    'Object',
  }
}
