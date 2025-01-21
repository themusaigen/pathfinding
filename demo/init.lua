script_name("pathfinding-demo")
script_version("1.0.0")
script_author("Musaigen")
script_description("The demonstration of pathfinding library features.")
-- -------------------------------------------------------------------------- --

local imgui = require("mimgui")
local pathfinding = require("pathfinding")

local renderer = require("core.renderer")

-- -------------------------------------------------------------------------- --

-- Pathfinding constants/shortcuts
local Point = pathfinding.INTERFACE.Point

-- ImGui constants/shortcuts.
local new = imgui.new
local ImVec2 = imgui.ImVec2

-- Format window name.
local window_name = ("Pathfinding %s-%s"):format(pathfinding._VERSION, pathfinding._RELEASE)

-- -------------------------------------------------------------------------- --

-- Main window bool.
local window = new.bool()

-- Algorithm choose.
local algorithm = new.int()
local algorithms = { "a*", "theta*" }
local algorithms_ptr = new["const char*"][#algorithms](algorithms)

-- Options / Path
local path_thickness = new.float(1)
local path_color = new.float[4](1, 1, 1, 1)

-- Options / Areas
local draw_areas = new.bool()
local areas_thickness = new.float(1)
local areas_color = new.float[4](1, 1, 1, 1)
local areas_text_shadow = new.bool(true)
local areas_text_color = new.float[4](1, 1, 1, 1)

-- Get screen resolution for first position set.
local screen_resolution = { getScreenResolution() }

-- Update target-blip info.
local blip = { getTargetBlipCoordinates() }

---@class Path
---@field a Vector|nil
---@field b Vector|nil
---@field output Vector[]|nil

---@type Path[]
local paths = {}

---@type Path|nil
local path = nil

-- -------------------------------------------------------------------------- --

local function get_player_position()
  if isCharInAnyCar(PLAYER_PED) then
    return Point.new(getCarCoordinates(storeCarCharIsInNoSave(PLAYER_PED)))
  else
    return Point.new(getCharCoordinates(PLAYER_PED))
  end
end

local function draw_pathing_tab()
  -- All buttons will have the same size.
  local button_size = ImVec2(imgui.GetWindowContentRegionWidth(), 25)

  if imgui.Button("New path", button_size) then
    -- New path.
    path = {}

    -- Add new path to the pool.
    paths[#paths + 1] = path
  end

  imgui.Separator()

  if path then
    if imgui.Button("Set A point (current position)", button_size) then
      path.a = get_player_position()
    end

    if imgui.Button("Set B point (current position)", button_size) then
      path.b = get_player_position()
    end

    if blip[1] then
      imgui.Separator()

      if imgui.Button("Set A point (by map)", button_size) then
        path.a = Point.new(blip[2], blip[3], blip[4])
      end

      if imgui.Button("Set B point (by map)", button_size) then
        path.b = Point.new(blip[2], blip[3], blip[4])
      end
    end

    imgui.Separator()

    imgui.Combo("Algorithm", algorithm, algorithms_ptr, #algorithms)

    if imgui.Button("Process pathfinding", button_size) then
      if path.a and path.b then
        path.output = pathfinding:process(algorithms[algorithm[0] + 1], path.a, path.b)
      end
    end
  end
end

local function draw_options_tab()
  imgui.Checkbox("Draw path areas", draw_areas)
end

local function draw_path_tab()
  imgui.SliderFloat("Path thickness", path_thickness, 1, 10)
  imgui.ColorEdit4("Path color", path_color)
end

local function draw_areas_tab()
  imgui.Checkbox("Draw text shadows", areas_text_shadow)
  imgui.SliderFloat("Thickness", areas_thickness, 1, 10)
  imgui.ColorEdit4("Line color", areas_color)
  imgui.ColorEdit4("Text color", areas_text_color)
end

-- -------------------------------------------------------------------------- --

imgui.OnInitialize(function()
  imgui.GetIO().IniFilename = nil
end)

imgui.OnFrame(function()
  return not isGamePaused()
end, function(player)
  -- Don't show cursor.
  player.HideCursor = true

  -- Some update stuff here.
  blip = { getTargetBlipCoordinates() }

  -- Render stuff here (yes, we will use imgui render features).
  local drawlist = imgui.GetBackgroundDrawList()

  -- Draw paths.
  for idx, path in ipairs(paths) do
    if path.a and path.b and draw_areas[0] then
      local area_color = renderer.convert_color(areas_color)
      local text_color = renderer.convert_color(areas_text_color)

      renderer.draw_area(drawlist, idx, path.a, path.b, area_color, areas_thickness[0], text_color, areas_text_shadow[0])
    end

    if path.output and #path.output > 0 then
      renderer.draw_path(drawlist, path.output, renderer.convert_color(path_color), path_thickness[0])
    end
  end
end)

imgui.OnFrame(function()
  return window[0] and not isGamePaused()
end, function()
  imgui.SetNextWindowSize(ImVec2(600, 400), imgui.Cond.FirstUseEver)
  imgui.SetNextWindowPos(ImVec2(screen_resolution[1] / 2, screen_resolution[2] / 2), imgui.Cond.FirstUseEver,
    ImVec2(0.5, 0.5))

  imgui.Begin(window_name, window)

  if imgui.BeginTabBar("##pathfinding-demo") then
    if imgui.BeginTabItem("Pathing") then
      draw_pathing_tab()

      imgui.EndTabItem()
    end

    if imgui.BeginTabItem("Options") then
      draw_options_tab()

      imgui.EndTabItem()
    end

    if imgui.BeginTabItem("Path settings") then
      draw_path_tab()

      imgui.EndTabItem()
    end

    if draw_areas[0] then
      if imgui.BeginTabItem("Area settings") then
        draw_areas_tab()

        imgui.EndTabItem()
      end
    end

    imgui.EndTabBar()
  end

  imgui.End()
end)

-- -------------------------------------------------------------------------- --

function main()
  while not isSampAvailable() do
    wait(0)
  end

  sampRegisterChatCommand("pf.demo", function()
    window[0] = not window[0]
  end)

  wait(-1)
end
