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
  return utility.reverse(path)
end

return utility
