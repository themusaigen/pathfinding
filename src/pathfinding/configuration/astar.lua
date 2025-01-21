-- File: astar.lua
-- Description: The module that implements A*-based algorithms configuration.
-- Author: themusaigen

---@class AstarConfiguration: Configuration
---@field private _data AstarInterface
local AstarConfiguration = {}
AstarConfiguration.__index = AstarConfiguration

-- Point class.
local Point = require("pathfinding.point")

---@alias Heuristics fun(self: AstarInterface, target: Vector, origin: Vector): number
---@alias Validate fun(self: AstarInterface, point: Vector): boolean
---@alias Collision fun(self: AstarInterface, target: Vector, origin: Vector): boolean
---@alias Neighbors fun(self: AstarInterface, step: number): Vector[]
---@alias IsEndReached fun(self: AstarInterface, end_point: Vector, point: Vector): boolean

---@class AstarInterface
---@field step number
---@field heuristics Heuristics
---@field validate Validate
---@field collision Collision
---@field neighbors Neighbors
---@field is_end_reached IsEndReached

--- Creates new A*-based configuration.
---@return AstarConfiguration
function AstarConfiguration.new()
  ---@type AstarInterface
  local default = {
    step = 1.5,
    heuristics = function(self, target, origin)
      return (target - origin):length()
    end,
    validate = function(self, point)
      return (point.z - getGroundZFor3dCoord(point:get())) <= 5
    end,
    collision = function(self, target, origin)
      return isLineOfSightClear(origin.x, origin.y, origin.z, target.x, target.y, target.z, true, true, false, true,
        false)
    end,
    neighbors = function(self, step)
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
    end,
    is_end_reached = function(self, end_point, point)
      return (end_point - point):length() <= self.step
    end
  }

  return setmetatable({ _data = default }, AstarConfiguration)
end

--- Sets new step.
---@param step number
function AstarConfiguration:set_step(step)
  assert(type(step) == "number")
  assert(step > 0)

  self._data.step = step
end

--- Sets new heuristics function.
---@param heuristics Heuristics
function AstarConfiguration:set_heuristics(heuristics)
  assert(type(heuristics) == "function")

  self._data.heuristics = heuristics
end

--- Sets new validate function.
---@param validate Validate
function AstarConfiguration:set_validate(validate)
  assert(type(validate) == "function")

  self._data.validate = validate
end

--- Sets new collision function.
---@param collision Collision
function AstarConfiguration:set_collision(collision)
  assert(type(collision) == "function")

  self._data.collision = collision
end

--- Sets new neighbors function
---@param neighbors Neighbors
function AstarConfiguration:set_neighbors(neighbors)
  assert(type(neighbors) == "function")

  self._data.neighbors = neighbors
end

--- Sets new end reached check function.
---@param end_reached IsEndReached
function AstarConfiguration:set_end_reached(end_reached)
  assert(type(end_reached) == "function")

  self._data.is_end_reached = end_reached
end

--- Returns the stored value.
---@param key ValueKey
---@return any
function AstarConfiguration:get(key)
  assert(type(key) == "string")
  assert(#key > 0)

  return self._data[key]
end

--- Calls the stored function.
---@param key FunctionKey
---@param ... any
function AstarConfiguration:call(key, ...)
  -- Get the function.
  ---@type function
  local fun = self:get(key)
  assert(type(fun) == "function")

  -- Call the function.
  return fun(self._data, ...)
end

return AstarConfiguration
