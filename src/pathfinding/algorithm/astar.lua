-- File: astar.lua
-- Description: The implementation of A* algorithm.
-- Author: themusaigen

local astar = {}

-- Node class.
local Node = require("pathfinding.node")

-- BinaryHeap class.
local BinaryHeap = require("pathfinding.binaryheap")

-- AstarConfiguration class.
local AstarConfiguration = require("pathfinding.configuration.astar")

-- Utilities.
local utility = require("pathfinding.utility")

--- Process A* algorithm.
---@param start pathfinding.Vector
---@param goal pathfinding.Vector
---@param configuration pathfinding.AstarConfiguration|nil
---@return pathfinding.Vector[]
function astar:process(start, goal, configuration)
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
  if not configuration:call("collision", start, start + height_point) then
    return {}
  elseif not configuration:call("collision", goal, goal + height_point) then
    return {}
  end

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
    visited[#visited + 1] = node

    -- Get neighbors to this node.
    local neighbors = {}
    for _, neighbor in ipairs(configuration:call("neighbors", configuration:get("step"))) do
      local next_point = node.point + neighbor

      if configuration:call("validate", next_point) then
        if configuration:call("collision", next_point, node.point) then
          neighbors[#neighbors + 1] = Node.new(next_point)
        end
      end
    end

    -- Iterate around all neighbors.
    for _, neighbor in ipairs(neighbors) do
      -- If we not visited that neighbor already.
      if not utility.find_node(visited, neighbor, configuration) then
        -- Calculate tentative G score.
        local tentative = node.g + configuration:call("heuristics", neighbor.point, node.point)

        -- Check is neighbor on tree.
        local success, idx = utility.find_node(tree:data(), neighbor, configuration)
        if success then
          -- Neighbor on the tree.
          local nfo = tree:get(idx)
          -- The current path is better than previous one.
          if tentative < nfo.g then
            nfo.g = tentative
            nfo.h = configuration:call("heuristics", end_node.point, nfo.point)
            nfo.f = nfo.g + nfo.h
            nfo.parent = node

            -- Sort all nodes.
            tree:repush(idx, nfo)
          end
        else
          neighbor.g = tentative
          neighbor.h = configuration:call("heuristics", end_node.point, neighbor.point)
          neighbor.f = neighbor.g + neighbor.h
          neighbor.parent = node

          -- Add new node into the tree.
          tree:push(neighbor)
        end
      end
    end
  end

  -- No path.
  return {}
end

return astar
