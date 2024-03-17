-- This is the configuration file for LÖVE. It's loaded before anything else,
-- and controls things like what features are enabled and what size the starting
-- game window is.

-- Here's the configuration.
local conf = {
  identity = 'ca.ancilla.mismap';
  version = '11.4'; -- love2d version

  window = {
    title = 'MISMap';
    icon = nil; -- FIXME: path to image
    -- FIXME: scale to screen
    width = 1280;
    height = 960;
    borderless = false;
    resizable = true;
    minwidth = 1; minheight = 1;
    fullscreen = false;
    fullscreentype = 'desktop'; -- borderless
    vsync = 1;
  };

  modules = {
    audio = false;
    data = true;
    event = true;
    font = true;
    graphics = true;
    image = true;
    joystick = false;
    keyboard = true;
    math = true;
    mouse = true;
    physics = false;
    sound = false;
    system = true;
    thread = false;
    timer = false;
    touch = false;
    video = false;
    window = true;
  };
}

-- This is a little utility function for combining the configuration above with
-- the default configuration built into LÖVE.
local function merge(dst, src, path)
  for k,v in pairs(src) do
    if type(dst[k]) == 'table' and type(v) == 'table' then
      merge(dst[k], v, path..'.'..k)
    elseif dst[k] ~= v then
      dst[k] = v
    end
  end
  return dst
end

-- And this is the function that actually does the configuring; it takes the
-- configuration at the top of this file and combines it with the default
-- configuration passed in by LÖVE.
function love.conf(t)
  merge(t, conf, 'config')
end
