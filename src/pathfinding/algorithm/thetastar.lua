-- File: thetastar.lua
-- Description: The implementation of Theta* algorithm (that based on A*).
-- Author: themusaigen

local thetastar = {}

-- Node class.
local Node = require("pathfinding.node")

-- BinaryHeap class.
local BinaryHeap = require("pathfinding.binaryheap")

-- AstarConfiguration class.
local AstarConfiguration = require("pathfinding.configuration.astar")

-- Utilities.
local utility = require("pathfinding.utility")

-- Hasher.
local hash = require("pathfinding.hash")

--- Process Theta* algorithm.
---@param start pathfinding.Vector
---@param goal pathfinding.Vector
---@param configuration pathfinding.AstarConfiguration|nil
---@return pathfinding.Vector[]
function thetastar:process(start, goal, configuration)
  configuration = configuration or AstarConfiguration.new()

  -- Create begin and end node.
  local begin_node = Node.new(start)
  local end_node = Node.new(goal)

  -- Calculate heuristics between goal and start.
  begin_node.f = configuration:call("heuristics", goal, start)

  -- Initialize binary heap.
  local tree = BinaryHeap.new()
  tree:push(begin_node)

  -- Check for collisions in begin and end point.
  -- If we have collision then this points is blocked.
  -- So we must return empty path to prevent infinity loop.
  local height_point = { x = 0, y = 0, z = 1 }
  if configuration:call("collision", start, start + height_point) then
    return {}
  elseif configuration:call("collision", goal, goal + height_point) then
    return {}
  end

  -- Cache step.
  local step = configuration:get("step")

  -- Initialize array of visited nodes.
  local visited = {}

  -- Until empty, process pathfinding.
  while #tree > 0 do
    -- Get node with lowest `f` score.
    local node = tree:pop()

    -- If we too close to the end node, force that case.
    if configuration:call("is_end_reached", end_node.point, node.point) then
      -- Mark current node as parent to reconstruct path properly.
      end_node.parent = node

      -- Reconstruct the path.
      return utility.reconstruct_path(end_node)
    end

    -- Mark as visited.
    visited[hash.hash_point(node.point)] = true

    -- Get neighbors to this node.
    local potential_neighbors = configuration:call("neighbors", step)
    local neighbors = {}
    for _, neighbor in ipairs(potential_neighbors) do
      local next_point = node.point + neighbor

      if not visited[hash.hash_point(next_point)] then
        if configuration:call("validate", next_point) then
          if not configuration:call("collision", next_point, node.point) then
            neighbors[#neighbors + 1] = Node.new(next_point)
          end
        end
      end
    end

    -- Iterate around all neighbors.
    for _, neighbor in ipairs(neighbors) do
      -- Try to find that neighbor in our tree.
      local index = tree:index_of(neighbor)

      -- If not found index, then reset neighbor's g score.
      if index == -1 then
        neighbor.g = math.huge
      else
        neighbor = tree:get(index)
      end

      if node.parent and not configuration:call("collision", node.parent.point, neighbor.point) then
        local parent_score = node.parent.g + configuration:call("heuristics", node.parent.point, neighbor.point)
        if parent_score < neighbor.g then
          neighbor.g = parent_score
          neighbor.h = configuration:call("heuristics", end_node.point, neighbor.point)
          neighbor.f = neighbor.g + neighbor.h
          neighbor.parent = node.parent

          if index == -1 then
            tree:push(neighbor)
          else
            tree:resort(index)
          end
        end
      else
        local node_score = node.g + configuration:call("heuristics", node.point, neighbor.point)
        if node_score < neighbor.g then
          neighbor.g = node_score
          neighbor.h = configuration:call("heuristics", end_node.point, neighbor.point)
          neighbor.f = neighbor.g + neighbor.h
          neighbor.parent = node

          if index == -1 then
            tree:push(neighbor)
          else
            tree:resort(index)
          end
        end
      end
    end
  end

  -- No path.
  return {}
end

return thetastar
