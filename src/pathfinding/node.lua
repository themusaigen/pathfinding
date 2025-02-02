-- File: node.lua
-- Description: Implementation of the graph node class to be used for pathfinding algorithms.
-- Author: themusaigen

---@class pathfinding.Node
---@field point pathfinding.Vector
---@field g number
---@field h number
---@field f number
---@field parent pathfinding.Node|nil
local Node = {}
Node.__classname = "Node"
Node.__index = Node

--- Creates new `Node` class instance.
---@param point pathfinding.Vector
---@return pathfinding.Node
function Node.new(point)
  assert(type(point) == "table")

  local self = setmetatable({
    point = point,
    g = 0,
    h = 0,
    f = 0,
    parent = nil
  }, Node)

  return self
end

--- Compares the total cost of two nodes and returns the lowest.
---@param a pathfinding.Node
---@param b pathfinding.Node
---@return boolean
function Node.__lt(a, b)
  assert(type(a) == "table")
  assert(type(b) == "table")
  assert(a.__classname == "Node")
  assert(b.__classname == "Node")
  return a.f < b.f
end

--- Compares the points of two nodes.
---@param a pathfinding.Node
---@param b pathfinding.Node
---@return boolean
function Node.__eq(a, b)
  assert(type(a) == "table")
  assert(type(b) == "table")
  assert(a.__classname == "Node")
  assert(b.__classname == "Node")
  return (a.point.x == b.point.x) and (a.point.y == b.point.y) and (a.point.z == b.point.z)
end

return Node
