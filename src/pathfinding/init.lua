-- File: init.lua
-- Description: The core file of `pathfinding` library.
-- Author: themusaigen

local pathfinding = {
  _NAME = "Pathfinding",
  _DESCRIPTION = "Library for implementing pathfinding algorithms in GTA:SA",
  _VERSION = "3.0.0",
  _RELEASE = "release",
  _AUTHOR = "Musaigen <blast.hk/members/194978/>",
  _URL = "https://github.com/themusaigen/pathfinding",
  _TOPIC_URL = "https://www.blast.hk/threads/229343/",

  -- The interface of the `pathfinding` library.
  INTERFACE = {
    Point = require("pathfinding.point"),
    AstarConfiguration = require("pathfinding.configuration.astar"),
    DynamicPathBuilder = require("pathfinding.builder.dynamic"),
    Node = require("pathfinding.node"),
    Hash = require("pathfinding.hash"),
    BinaryHeap = require("pathfinding.binaryheap"),
    Utility = require("pathfinding.utility"),
  },
}

---@class pathfinding.Configuration
---@field set fun(self: pathfinding.Configuration, key: string, value: any)
---@field get fun(self: pathfinding.Configuration, key: string): any
---@field call fun(self: pathfinding.Configuration, key: string, ...: any): any

---@class pathfinding.Algorithm
---@field process fun(self: pathfinding.Algorithm, start: pathfinding.Vector, goal: pathfinding.Vector, configuration: pathfinding.Configuration|nil): pathfinding.Vector[]

local cache = require("pathfinding.cache")

--- Executs the speficic pathfind algorithm.
---@param algorithm string
---@param start pathfinding.Vector
---@param goal pathfinding.Vector
---@param configuration pathfinding.Configuration|nil
function pathfinding:process(algorithm, start, goal, configuration)
  assert(type(algorithm) == "string")
  assert(#algorithm > 0)
  assert(type(start) == "table")
  assert(type(goal) == "table")

  if configuration then
    assert(type(configuration) == "table")
  end

  return cache.get_algorithm(algorithm):process(start, goal, configuration)
end

return pathfinding
