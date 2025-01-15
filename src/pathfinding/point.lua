-- File: point.lua
-- Description: Implementation of a coordinate point class in 3D space.
-- Author: themusaigen

---@class Point
local Point = {}
Point.__call = function(self, ...)
  return Point.new(...)
end

---@class Vector
---@field x number
---@field y number
---@field z number
---@field get fun(self: Vector): (number, number, number)
---@field length fun(self: Vector): (number)
---@field normalize fun(self: Vector): (number)
---@field zeroNearZero fun(self: Vector)
---@field zero_near_zero fun(self: Vector)
---@field dotProduct fun(self: Vector, other: Vector): number
---@field dot_product fun(self: Vector, other: Vector): number
---@field crossProduct fun(self: Vector, other: Vector)
---@field cross_product fun(self: Vector, other: Vector)
---@operator add(Vector): Vector
---@operator mul(number): Vector
---@operator mul(Vector): Vector
---@operator sub(Vector): Vector

---@type fun(x: number|integer|nil, y: number|integer|nil, z: number|integer|nil): Vector
local Vector3D = require("vector3d")

--- Creates new `Point` class instance.
---@param x any
---@param ... any
---@return Vector
function Point.new(x, ...)
  if type(x) == "table" then
    if type(x[0]) == "number" then
      return Vector3D(x[0] or 0, x[1] or 0, x[2] or 0)
    elseif type(x[1]) == "number" then
      return Vector3D(x[1] or 0, x[2] or 0, x[3] or 0)
    elseif type(x.x) == "number" then
      return Vector3D(x.x or 0, x.y or 0, x.z or 0)
    end
  elseif type(x) == "number" then
    local args = { ... }
    return Vector3D(x, args[1] or 0, args[2] or 0)
  end

  return Vector3D(0, 0, 0)
end

return Point
