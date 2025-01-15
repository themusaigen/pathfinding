-- File: utility.lua
-- Description: Utilities for all pathfinding algorithms.
-- Author: themusaigen

local utility = {}

-- Point class.
local Point = require("pathfinding.point")

--- Reverses the table.
---@param list table
---@return table
function utility.reverse(list)
  for i = 1, math.floor(#list / 2), 1 do
    list[i], list[#list - i + 1] = list[#list - i + 1], list[i]
  end
  return list
end

--- Smoothes the path edges. Source: https://www.blast.hk/threads/228996/post-1578444
---@param path Vector[]
---@return Vector[]
function utility.smooth_path(path)
  local out = {}
  for i = 2, #path - 2 do
    local p0, p1, p2, p3 = path[i - 1], path[i], path[i + 1], path[i + 2]
    for t = 0, 1, 0.1 do
      local t2 = t * t
      local t3 = t2 * t
      local x = 0.5 *
          ((2 * p1.x) + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
      local y = 0.5 *
          ((2 * p2.y) + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p2.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p2.y - 3 * p2.y + p3.y) * t3)
      local z = 0.5 *
          ((2 * p1.z) + (-p0.z + p2.z) * t + (2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t2 + (-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t3)
      table.insert(out, Point.new(x, y, z))
    end
  end
  return out
end

--- Clamps the value with two bounds.
---@param x number
---@param min number
---@param max number
---@return number
function utility.clamp(x, min, max)
  return math.min(max, math.max(x, min))
end

--- Reconstructs path from begin to end.
---@param node Node
---@return Vector[]
function utility.reconstruct_path(node)
  local path = {}

  -- Reconstruct path from end to start.
  while node do
    -- To avoid access to nil errors, we recreate the point.
    path[#path + 1] = Point.new(node.point)

    -- Switch to the next node.
    node = node.parent
  end

  -- From `end to start` -> `start to end`
  return utility.smooth_path(utility.reverse(path))
end

return utility
