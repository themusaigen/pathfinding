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

--- Creates default configuration or fills empty fields.
---@param configuration Configuration|nil
---@return Configuration
function utility.create_configuration(configuration)
  configuration = configuration or {}

  -- Default step size.
  configuration.Step = configuration.Step or 1.5

  -- Default heuristic function.
  configuration.Heuristic = configuration.Heuristic or function(self, target, origin)
    return (target - origin):length()
  end

  -- Default validate function. Checks for height difference.
  configuration.Validate = configuration.Validate or function(self, point)
    return math.abs(point.z - getGroundZFor3dCoord(point:get())) <= 5
  end

  -- Default collision function.
  configuration.Collision = configuration.Collision or function(self, target, origin)
    return isLineOfSightClear(origin.x, origin.y, origin.z, target.x, target.y, target.z, true, true, false, true, false)
  end

  -- Default neighbors function.
  configuration.Neighbors = configuration.Neighbors or function(self, step)
    return {
      Point.new(step), Point.new(-step),
      Point.new(0, step), Point.new(0, -step),
      Point.new(0, 0, step), Point.new(0, 0, -step),

      Point.new(step, step), Point.new(-step, -step),
      Point.new(step, -step), Point.new(-step, step),

      Point.new(step, step, step), Point.new(-step, -step, -step),
      Point.new(-step, step, step), Point.new(step, -step, -step),
      Point.new(step, -step, step), Point.new(-step, step, -step),
      Point.new(step, step, -step), Point.new(-step, -step, step),
      Point.new(step, 0, step), Point.new(-step, 0, -step)
    }
  end

  -- Default function of checking is we reached end.
  configuration.ReachedEnd = configuration.ReachedEnd or function(self, end_point, point)
    return self:Heuristic(end_point, point) <= self.Step
  end

  return configuration
end

--- Try to find node in list.
---@param list table
---@param n Node
---@param configuration Configuration
---@return boolean, number
function utility.find_node(list, n, configuration)
  for idx = 1, #list do
    local node = list[idx]

    if configuration:Heuristic(node.point, n.point) < configuration.Step then
      return true, idx
    end
  end
  return false, -1
end

return utility
