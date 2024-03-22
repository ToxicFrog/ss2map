setgamesys 'dark.gam'

defcategory 'Loot' {
  colour = '#00ffff';
  visible = true;
  info = 'Coins, gems, jewelry, and other forms of filthy lucre.';
  types = {
    'Object/Physical/Treasure',
  };
}

defcategory 'Supplies & Equipment' {
  colour = '#8080ff';
  visible = true;
  info = 'Arrows, potions, grenades, etc.';
  types = {
    -- TODO: split these up more?
    'Object/Physical/Projectile/Broadhead',
    'Object/Physical/Projectile/EarthArrow',
    'Object/Physical/Projectile/FireArrow',
    'Object/Physical/Projectile/GasArrow',
    'Object/Physical/Projectile/RopeArrow',
    'Object/Physical/Projectile/Water',
    'Object/Physical/Tulz/Crystal',
    'Object/Physical/Tulz/Grenadz',
    'Object/Physical/Tulz/Potion',
  };
}

defcategory 'Keys' {
  colour = '#80ff80';
  visible = true;
  types = {
    'Object/Physical/Key',
  };
}

defcategory 'Books & Scrolls' {
  colour = '#80ff80';
  visible = true;
  types = {
    'Object/Physical/Household/Book',
    'Object/Physical/Household/Scroll',
  }
}

defcategory 'Bystanders' {
  colour = '#FF8080';
  visible = true;
  info = 'Unarmed civilians.';
  types = {
    'Object/Physical/Creature/Animal/Human/Bystander',
  };
}

defcategory 'Guards' {
  colour = '#FF0000';
  visible = true;
  info = 'Guards, hammerites, etc.';
  types = {
    'Object/Physical/Creature/Animal/Human',
  };
}

defcategory 'Other Threats' {
  colour = '#FF0000';
  visible = true;
  info = 'Zombies, elementals, robots, giant spiders...';
  types = {
    'Object/Physical/Creature/Beast',
    'Object/Physical/Creature/Elemental',
    'Object/Physical/Creature/Robot',
    'Object/Physical/Creature/Undead',
  };
}

defcategory 'Containers' {
  colour = '#A0A0A0';
  visible = true;
  info = 'Things that can contain other things.';
  types = {
    'Object/Physical/Container',
  };
}

defcategory 'Controls' {
  colour = '#00ff00';
  visible = true;
  info = 'Switches, buttons, and pressure plates.';
  types = {
    'Object/Physical/Gizmo/Switches',
    'Object/Physical/TerrainLike/PressPlate',
  };
}

defcategory 'Doors' {
  colour = '#A0A000';
  visible = true;
  types = {
    'Object/Physical/TerrainLike/Door',
  };
}

defcategory 'Lights' {
  colour = '#FFFF00';
  types = {
    'Object/Physical/Lights',
  };
}

defcategory 'Furniture' {
  colour = '#ffffff';
  types = {
    'Object/Physical/Furniture',
  }
}

defcategory 'Decor' {
  colour = '#ffffff';
  types = {
    'Object/Physical/Decorative',
  }
}

defcategory 'Traps & Triggers' {
  colour = '#FFFFFF';
  info = 'The hidden machinery of the level.';
  types = {
    'Object/Fnord',
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
  types = {
    'Object',
  }
}

