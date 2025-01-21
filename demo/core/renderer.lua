-- File: renderer.lua
-- Description: Renderer file for pathfinding-demo.
-- Author: themusaigen

local renderer = {}

-- -------------------------------------------------------------------------- --

-- Point class.
local Point = require("pathfinding.point")

-- ImGui library.
local imgui = require("mimgui")

-- -------------------------------------------------------------------------- --

local ImVec2 = imgui.ImVec2

-- -------------------------------------------------------------------------- --

---@type ImVec2
local half_unit_vec = ImVec2(0.5, 0.5)

-- -------------------------------------------------------------------------- --

local function join_argb(a, r, g, b)
  local argb = b                          -- b
  argb = bit.bor(argb, bit.lshift(g, 8))  -- g
  argb = bit.bor(argb, bit.lshift(r, 16)) -- r
  argb = bit.bor(argb, bit.lshift(a, 24)) -- a
  return argb
end

--- Converts a float[4] color to ImU32
--- @param float4 number[]
--- @return integer
function renderer.convert_color(float4)
  -- WHY??? ABGR format :(
  return join_argb(float4[3] * 255, float4[2] * 255, float4[1] * 255, float4[0] * 255)
end

--- Converts 3D position to screen position, also checks is point visible on screen.
---@param pos Vector
---@return boolean
---@return ImVec2|nil
local function convert_3d_to_screen(pos)
  if isPointOnScreen(pos.x, pos.y, pos.z, 0) then
    return true, ImVec2(convert3DCoordsToScreen(pos:get()))
  else
    return false, nil
  end
end

--- Draws a line in 3D space.
---@param drawlist table
---@param pos0 Vector
---@param pos1 Vector
---@param color integer
---@param thickness number|nil
function renderer.draw_line3d(drawlist, pos0, pos1, color, thickness)
  local success0, origin = convert_3d_to_screen(pos0)
  local success1, target = convert_3d_to_screen(pos1)

  if success0 and success1 then
    drawlist:AddLine(origin, target, color, thickness)
  end
end

--- Draws a text.
---@param drawlist table
---@param text string
---@param pos Vector
---@param color integer
---@param shadow boolean|nil
function renderer.draw_text(drawlist, text, pos, color, shadow)
  local success, origin = convert_3d_to_screen(pos)

  if success then
    if shadow then
      drawlist:AddText(origin - half_unit_vec, 0xFF000000, text)
      drawlist:AddText(origin + half_unit_vec, 0xFF000000, text)
    end

    drawlist:AddText(origin, color, text)
  end
end

--- Draws one of rect sides (bottom, top)
---@param drawlist table
---@param a Vector
---@param lt Vector # Left top offset.
---@param rt Vector # Right top offset.
---@param rb Vector # Right bottom offset.
---@param color integer
---@param thickness number|nil
function renderer.draw_rect_side(drawlist, a, lt, rt, rb, color, thickness)
  renderer.draw_line3d(drawlist, a, a + lt, color, thickness)
  renderer.draw_line3d(drawlist, a + lt, a + rt, color, thickness)
  renderer.draw_line3d(drawlist, a + rt, a + rb, color, thickness)
  renderer.draw_line3d(drawlist, a + rb, a, color, thickness)
end

--- Draws rect edges.
---@param drawlist table
---@param a Vector
---@param lt Vector # Left top offset.
---@param rt Vector # Right top offset.
---@param rb Vector # Right bottom offset.
---@param color integer
---@param thickness number|nil
function renderer.draw_rect_edges(drawlist, a, lt, rt, rb, height, color, thickness)
  -- Top point constant.
  local top_point_offset = Point.new(0, 0, height)

  -- Drawing.
  renderer.draw_line3d(drawlist, a, a + top_point_offset, color, thickness)
  renderer.draw_line3d(drawlist, a + lt, a + lt + top_point_offset, color, thickness)
  renderer.draw_line3d(drawlist, a + rt, a + rt + top_point_offset, color, thickness)
  renderer.draw_line3d(drawlist, a + rb, a + rb + top_point_offset, color, thickness)
end

--- Draws the area
---@param drawlist table
---@param id number
---@param a Vector
---@param b Vector
---@param color integer
---@param thickness number|nil
---@param text_color integer
---@param shadow boolean
function renderer.draw_area(drawlist, id, a, b, color, thickness, text_color, shadow)
  -- Compute size.
  local size = b - a
  size:zero_near_zero()

  -- Offsets.
  local left_top = Point.new(0, size.y)
  local right_top = Point.new(size.x, size.y)
  local right_bottom = Point.new(size.x)

  -- Draw bottom side.
  renderer.draw_rect_side(drawlist, a, left_top, right_top, right_bottom, color, thickness)

  -- Draw top side and edges if needed.
  if math.abs(size.z) >= 0.5 then
    -- Draw edges.
    renderer.draw_rect_edges(drawlist, a, left_top, right_top, right_bottom, size.z, color, thickness)

    -- Draw top side.
    renderer.draw_rect_side(drawlist, a + Point.new(0, 0, size.z), left_top, right_top, right_bottom, color, thickness)
  end

  -- Draw text.
  renderer.draw_text(drawlist, "Area #" .. id, a + size * 0.5, text_color, shadow)
  renderer.draw_text(drawlist, "Point A", a, text_color, shadow)
  renderer.draw_text(drawlist, "Point B", b, text_color, shadow)
end

--- Renders a path.
---@param drawlist table
---@param path Vector[]
---@param color integer
---@param thickness number|nil
function renderer.draw_path(drawlist, path, color, thickness)
  for i = 1, #path - 1 do
    local point = path[i]
    local next_point = path[i + 1]

    renderer.draw_line3d(drawlist, point, next_point, color, thickness)
  end
end

return renderer
