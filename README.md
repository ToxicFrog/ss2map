# ss2map -- tools for System Shock 2 map inspection

This repo contains some small tools for examining System Shock 2 maps. (It also
works on Thief 1/2 maps, but that is not the main focus and some things do not
work as well.)

Currently it contains three tools:

- `mislist`, for listing map contents
- `misview`, for viewing map geometry
- `mishtml`, for generating an interactive, searchable HTML map

The first two are primarily useful for testing and debugging. `mishtml` is the
main focus, and is what is used to generate [these online SS2 maps](https://funkyhorror.ancilla.ca/toxicfrog/maps/ss2).

It also contains a Lua library for reading Dark Engine tagfiles (`.MIS`/`.GAM`),
in `db`. It is fairly minimal and only supports the subset of file contents needed
for these tools, but is designed for extensibility.

## Prerequisites and Setup

All of these programs are written in Lua. They are only tested with [LuaJIT](https://luajit.org/),
although they may work with Lua 5.2+ as well. Even if they do, LuaJIT is recommended
for performance reasons.

They also require [vstruct](https://github.com/toxicfrog/vstruct/) and
[this util library](https://github.com/toxicfrog/luautil/). Both are included in
the repo as git submodules, so you should already have them available if you are
running directly out of the working copy.

`misview` and `mishtml` additionally require the [love2d game engine](https://love2d.org/),
which is used for rendering and (in the former) input handling. Due to limitations
in Love2d's graphics subsystem, `mishtml` cannot operate headless, sorry.

### Property definitions (proplist.txt)

In order to deserialize and display object properties, the programs require a
`proplist.txt` file, which lists all of the properties supported by the Dark
Engine and their corresponding types. For convenience, these are built in; you
can find them in the `proplists` directory:

- `ss2.proplist`: System Shock 2 v2.48
- `t1.proplist`: Thief Gold v1.26
- `t2.proplist`: Thief 2 v1.25

The Lua files in that directory contain additional information about on-disk
property layout not included in the `proplist.txt`. To select one of these, use
the `--propformat` command line flag, e.g. `--propformat ss2`.

#### Adding support for new properties

See [proplists/README.md](./proplists/README.md) for detailed instructions on
both how to add support for individual properties, and how to generate a new
proplist file to support a different engine version.

### Gamesys (shock2.gam)

In order to read object type information and inherited properties, the programs
require a gamesys. This is (by default) called `shock2.gam` for System Shock 2,
and `dark.gam` for Thief and Thief 2. If you have mods installed they may use a
different gamesys; notably, the SCP fan-patch for System Shock 2 uses `shockscp.gam`.
Make sure you're using the right one!

### Mission files (*.mis)

These contain the actual map data. Unfortunately the MIS files that come with the
games have some data removed to save space (known as "stripping"). If you're using
the latest fan-patches you probably don't need to worry about this:

- **Thief 1/Gold:** [TFix](https://www.ttlg.com/forums/showthread.php?t=134733) includes unstripped missions.
- **Thief 2:** the "with mods" version of [T2Fix](https://www.ttlg.com/forums/showthread.php?t=149669) includes unstripped missions; you can also install [AM16's Fixes](https://www.ttlg.com/forums/showthread.php?t=141121) separately if you don't want the other T2Fix mods.
- **System Shock 2:** the [Shock Community Patch](https://www.systemshock.org/index.php?topic=7116.0) includes unstripped missions.

If you need to work with stripped levels, you can restore the stripped data by
opening them up in a recent version of ShockEd or DromEd and using the
`Extra -> Reconstruct Stripped -> Room Brushes` command.

## Included Tools

All tools are launched from a `bash` wrapper script which handles checking for
`luajit` or `love`, setting up necessary environment variables, and then launching
the actual program.

All commands can be run with `--help` to list all supported command line flags.

Note that all tools use the (x,y) coordinates for objects as stored in the mission
file. This does not neccessarily correspond to the in-game compass and automap
(which can be set arbirarily relative to the MIS file).

### mislist

This produces a textual listing of all objects in the level. By default it shows
name, ID, position, and orientation; it can optionally display object properties
(direct and inherited), ancestry chains (MetaProp and archetype), and interobject
links.

Example usage:

    mislist \
      --propformat ss2 \
      --gamesys ss2/shockscp.gam \
      --links --props --inherited --ancestry \
      ss2/medsci1.mis

Used in conjunction with standard text processing tools like `grep`, this can also
be used to do things like produce quick summaries of how many instances of a given
object are in each level.

### misview

This presents an interactive view of the level terrain. It is not nearly as capable
as the exported HTML map, but uses the same rendering code as the HTML exporter,
and is thus primarily useful for quickly testing changes to the map loader and
renderer.

It can load multiple maps at once:

    misview \
      --propformat ss2 \
      --gamesys ss2/shockscp.gam \
      ss2/*.mis

Once loaded, the following controls are available:

    arrow keys or click + drag: pan view
    w/s: zoom in/out
    n/p: next/previous map
    i: switch between interior (detail) and exterior (outline) view
    r: hot-reload renderer
    q: quit

### mishtml

This generates an interactive HTML map of the given level(s) and drops it into `www/`.
The entry point is `www/map.html`. This can be viewed locally or uploaded to a web
server.

The terrain is pre-rendered and exported as a PNG, while object data is exported
as JSON and rendered in the browser. Under the hood this shares most of its implementation
with `misview`, but has a different command line interface.

If you just need to regenerate the JSON but not the terrain images, use the
`--no-genimages` command line flag to speed things up significantly by skipping
terrain generation.

Information about the game to generate maps for, including which maps to load
in what order and how objects should be categorized, is stored in separate
*gameinfo scripts* for each game, loaded with `--gameinfo`. You also need a
`--gamedir` so that it knows what directory to look for the map and gamesys files
in.

    mkdir -p maps/ss2/
    mishtml \
      --html-out maps/ss2 \
      --propformat ss2 \
      --gamedir ss2 \
      --gameinfo gameinfo/ss2-objects.lua,gameinfo/ss2-maps.lua

You can also omit the gameinfo that lists the maps and instead list maps on the
command line, at the cost of losing some useful map metadata in the UI:

    mkdir -p maps/ss2/
    mishtml \
      --html-out maps/ss2 \
      --propformat ss2 \
      --gamesys ss2/shockscp.gam \
      --gameinfo gameinfo/ss2-objects.lua \
      ss2/{earth,station,eng,medsci,hydro,ops,rec,command}*.mis

#### Using the Map

The center display shows the map. Circles are entities, lines and boxes are terrain.
You can click and drag to pan, and use the mousewheel to zoom. Mousing over an entity
will display its information in the lower right, and you can click to "lock" the
information and keep it there even as you mouse over other things.

The top left display lets you coarsely control which categories of entities are
displayed on the map, which is useful if you are only interested in specific things.

The top right lets you search. You can search by object name (e.g. `20 nanites`),
object ID (e.g. `144`), or slash-separated object type, e.g. `goodies/nanites`.
The search is a case-insentive substring search and will list all objects in the
level (or, with `Search All`, across all levels) matching it; they will also be
marked on the map with stars. Mousing over an object in the list will hilight it
on the map and display its object info in the lower left.

Searches will also return all containers that contain the searched-for object, so
if you search for (e.g.) `audio log`, you will also see crates, corpses, etc in
the search results -- mouse over them to view their contents.

## Known Issues and Future Work

- The terrain renderer currently assumes all terrain brushes are rectangular prisms. This works remarkably well but produces obviously wrong results in a few places. Support for cylinders, pyramids, offset pyramids, and spheres is needed.
- The terrain renderer is not good at detecting interior walls constructed via additive geometry.
- The terrain renderer does not support Z-slicing. This is necessary to sensibly support room-over-room, which is an issue for some SS2 maps and most Thief maps.
- The proplist loader does not support aggregate types (since proplist.txt does not contain sufficient information to decode them). Support for at least some common types, like position and dimensions, should be added.
- The proplist loader does not support bitflags.
- All of these programs assume that Y increases towards the top of the screen and X increases towards the right, i.e. southwest gravity. In ShockEd, however, X increases towards the *bottom* of the screen and Y to the *right*, i.e. northwest gravity *with horizontal Y and vertical X*. Since everything else assumes Y is vertical and X is horizontal, fixing this will require some care, although the actual changes needed are probably not extensive.
- The cute little map icons are hardcoded in the javascript, and thus don't match up with the actual maps as exported if you only export a subset of SS2 maps, or export them in a different order.
- Support for `.DIF` files (easy, they're just another tagfile) and `.DML` files (needs another bespoke parser).
- Support for `objshort.str` (localized object names) and `levelNN.str` (audio log titles)
- Ability to read map info out of a separate file, so that map icons and titles don't need to be hardcoded in the frontend and can be different for e.g. Thief vs SS2.

## Credits

Implementation by Rebecca Kelly (ToxicFrog); developed in cooperation with
[Night Dive Studios](https://www.nightdivestudios.com/).

In addition, study of Telliamed's [DarkLib](https://whoopdedo.org/projects.php?dark)
shed considerable light on some details of Dark Engine file formats.

