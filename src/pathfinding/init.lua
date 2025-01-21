-- File: init.lua
-- Description: The core file of `pathfinding` library.
-- Author: themusaigen

local pathfinding = {
  _NAME = "Pathfinding",
  _DESCRIPTION = "Library for implementing pathfinding algorithms in GTA:SA",
  _VERSION = "2.0.0",
  _RELEASE = "release",
  _AUTHOR = "Musaigen <blast.hk/members/194978/>",
  _URL = "https://github.com/themusaigen/pathfinding",
  _TOPIC_URL = "https://www.blast.hk/threads/229343/",

  -- The interface of the `pathfinding` library.
  INTERFACE = {
    Point              = require("pathfinding.point"),
    AstarConfiguration = require("pathfinding.configuration.astar")
  }
}

-- The list for replaces in algorithm names.
local possible_replaces = {
  ["*"] = "star"
}

---@alias FunctionKey string | "heuristics" | "is_end_reached" | "validate" | "collision" | "neighbors"
---@alias ValueKey string | "step" | FunctionKey

---@class Configuration
---@field get fun(self: Configuration, key: ValueKey): any
---@field call fun(self: Configuration, key: FunctionKey, ...: any): any

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

return pathfinding
