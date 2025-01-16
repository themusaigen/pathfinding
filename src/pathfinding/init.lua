-- File: init.lua
-- Description: The core file of `pathfinding` library.
-- Author: themusaigen

local pathfinding = {
  _NAME = "Pathfinding",
  _DESCRIPTION = "Library for implementing pathfinding algorithms in GTA:SA",
  _VERSION = "1.0.1",
  _RELEASE = "alpha",
  _AUTHOR = "Musaigen <blast.hk/members/194978/>"
}

-- The list for replaces in algorithm names.
local possible_replaces = {
  ["*"] = "star"
}

---@class Configuration
---@field Validate fun(self: Configuration, point: Vector): boolean
---@field Collision fun(self: Configuration, target: Vector, origin: Vector): boolean
---@field Heuristic fun(self: Configuration, node0: Node, node1: Node): number
---@field Neighbors fun(self: Configuration, step: number): Vector[]
---@field Step number

---@class Algorithm
---@field process fun(self: Algorithm, start: Vector, goal: Vector, configuration: Configuration|nil): Vector[]

-- The cache of all used algorithms.
---@type Algorithm[]
local algorithms = {}

--- Executs the speficic pathfind algorithm.
---@param algorithm string
---@param start Vector
---@param goal Vector
---@param configuration Configuration|nil
function pathfinding:process(algorithm, start, goal, configuration)
  assert(type(algorithm) == "string")
  assert(#algorithm > 0)
  assert(type(start) == "table")
  assert(type(goal) == "table")

  if configuration then
    assert(type(configuration) == "table")
  end

  -- Process a replacings.
  algorithm = algorithm:lower()
  for pattern, replace in pairs(possible_replaces) do
    algorithm = algorithm:gsub(pattern, replace)
  end

  -- Precache algorithm.
  if not algorithms[algorithm] then
    algorithms[algorithm] = require("pathfinding.algorithm." .. algorithm)
  end

  -- Process pathfinding.
  return algorithms[algorithm]:process(start, goal, configuration)
end

-- Add `Point` class for user.
pathfinding.Point = require("pathfinding.point")

return pathfinding
