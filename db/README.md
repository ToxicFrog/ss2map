# Dark Engine database library

This library provides a convenient way to access the contents of one or more
tag files (GAM or MIS). See `init.lua` for the high-level interface, and
`object.lua` and `link.lua` for object- and link-specific APIs. The rest of this
file contains a brief overview of the API.

For a program showing the whole API in action, see `mislist`.

First, create a database and load some files into it:

    local DB = require 'db'
    local db = DB.new()
    -- Load the proplist.txt first, if you want support for entity properties
    db:load_proplist('proplist.txt')
    -- Then load the gamesys and mission file
    db:load('shock2.gam')
    db:load('earth.mis')

Having done so, you can extract individual objects from it by ID. The DB contains
multiple object types and IDs *are not unique across types*, e.g. there can be both
an `entity` object with ID 1 and a `brush` object with ID 1. If you don't specify
an object type, `entity` is assumed, which covers both all in-game objects other
than terrain, and object archetypes stored in the gamesys.

    -- Get entity #1
    print(db:object(1))
    -- Get brush #1
    print(db:object(1, 'brush'))

You can also iterate over all objects in the DB, or all objects of a given type:

    -- Everything; note that ID is not guaranteed to be unique
    for id,obj in db:objects() do
      print(object)
    end

    -- All links; ID is guaranteed unique within a single type
    for id,obj in db:objects('link') do
      print(object)
    end

Individual objects contain fields specific to the object type; e.g. a brush will
have `position` and `rotation` fields (among others), and a link will have `src`,
`dst`, and `tag`. Entities can also have `properties`, which can be applied directly
to the entity or inherited via a `MetaProp` link. You can read individual properties
with `getProperty()`; the second argument lets you turn off `MetaProp` traversal
and only read properties set directly on the object:

    -- Display the object's Immobile property
    print(obj:getProperty('Immobile'))
    -- Display it only if it's set directly on the object; if it's set via MetaProp,
    -- this will return nil.
    print(obj:getProperty('Immobile', false))

You can also iterate all properties on the object; unlike getProperty this defaults
to *not* iterating MetaProps. Rather than returning the value, this returns a table
containing `{ obj = containing object; key = property name; value = property value }`;
the `obj` field can be used to differentiate direct properties from MetaProp-derived
properties.

    for prop in obj:getProperties(true) do
      if prop.src == obj then
        print('local', prop.key, prop.value)
      else
        print('inherited', prop.key, prop.value)
      end
    end

Entities can also have *links*, which relate entities to each other; these can be
iterated with `getLinks()`:

    for link in obj:getLinks() do
      print(link)
    end

You can pass a link type (e.g. `'TPath'` or `'MetaProp'`) to iterate only links
of that type. Note that (unlike properties) there is no API for requesting a single
link of a given type as entities can, and often do, have multiple links of the same
type.
