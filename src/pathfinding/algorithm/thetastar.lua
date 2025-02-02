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
      if not utility.find_node(visited, neighbor, configuration) then
        local success, idx = utility.find_node(tree:data(), neighbor, configuration)

        if not success then
          neighbor.g = math.huge
        else
          neighbor = tree:get(idx)
        end

        if node.parent and configuration:call("collision", node.parent.point, neighbor.point) then
          local parent_score = node.parent.g + configuration:call("heuristics", node.parent.point, neighbor.point)
          if parent_score < neighbor.g then
            neighbor.g = parent_score
            neighbor.h = configuration:call("heuristics", end_node.point, neighbor.point)
            neighbor.f = neighbor.g + neighbor.h
            neighbor.parent = node.parent

            if success then
              tree:remove(idx)
            end

            tree:push(neighbor)
          end
        else
          local node_score = node.g + configuration:call("heuristics", node.point, neighbor.point)
          if node_score < neighbor.g then
            neighbor.g = node_score
            neighbor.h = configuration:call("heuristics", end_node.point, neighbor.point)
            neighbor.f = neighbor.g + neighbor.h
            neighbor.parent = node

            if success then
              tree:remove(idx)
            end

            tree:push(neighbor)
          end
        end
      end
    end
  end

  -- No path.
  return {}
end

return thetastar
