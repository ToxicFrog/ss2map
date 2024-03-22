function initCategories() {
  let div = document.getElementById("layercontrols")
  let rows = [];
  for (let i in CATEGORIES) {
    let cat = CATEGORIES[i]
    cat.index = i
    rows.push('<label title="'
      + cat.types.join('\n')
      + '"><input type="checkbox"'
      + (cat.visible ? ' checked' : '')
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
