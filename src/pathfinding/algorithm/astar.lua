-- File: astar.lua
-- Description: The implementation of A* algorithm.
-- Author: themusaigen

local astar = {}

-- Point class.
local Point = require("pathfinding.point")

-- Node class.
local Node = require("pathfinding.node")

-- BinaryHeap class.
local BinaryHeap = require("pathfinding.binaryheap")

-- Utilities.
local utility = require("pathfinding.utility")

--- Creates configuration.
---@param configuration Configuration|nil
---@return Configuration
local function create_configuration(configuration)
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
local function find(list, n, configuration)
  for idx = 1, #list do
    local node = list[idx]

    if configuration:Heuristic(node.point, n.point) < configuration.Step then
      return true, idx
    end
  end
  return false, -1
end

--- Process A* algorithm.
---@param start Vector
---@param goal Vector
---@param configuration Configuration|nil
---@return Vector[]
function astar:process(start, goal, configuration)
  configuration = create_configuration(configuration)

  -- Create begin and end node.
  local begin_node = Node.new(start)
  local end_node = Node.new(goal)

  -- Initialize binary heap.
  local tree = BinaryHeap.new()
  tree:push(begin_node)

  -- Initialize array of visited nodes.
  local visited = {}

  -- Until empty, process pathfinding.
  while #tree > 0 do
    -- Get node with lowest `f` score.
    local node = tree:pop()

    -- If we too close to the end node, force that case.
    if configuration:ReachedEnd(end_node.point, node.point) then
      -- Mark current node as parent to reconstruct path properly.
      end_node.parent = node

      -- Reconstruct the path.
      return utility.reconstruct_path(end_node)
    end

    -- Mark as visited.
    visited[#visited + 1] = node

    -- Get neighbors to this node.
    local neighbors = {}
    for _, neighbor in ipairs(configuration:Neighbors(configuration.Step)) do
      local next_point = node.point + neighbor

      if configuration:Validate(next_point) then
        if configuration:Collision(next_point, node.point) then
          neighbors[#neighbors + 1] = Node.new(next_point)
        end
      end
    end

    -- Iterate around all neighbors.
    for _, neighbor in ipairs(neighbors) do
      -- If we not visited that neighbor already.
      if not find(visited, neighbor, configuration) then
        -- Calculate tentative G score.
        local tentative = node.g + configuration:Heuristic(neighbor.point, node.point)

        -- Check is neighbor on tree.
        local success, idx = find(tree:data(), neighbor, configuration)
        if success then
          -- Neighbor on the tree.
          local nfo = tree:get(idx)
          -- The current path is better than previous one.
          if tentative < nfo.g then
            nfo.g = tentative
            nfo.h = configuration:Heuristic(end_node.point, nfo.point)
            nfo.f = nfo.g + nfo.h
            nfo.parent = node

            -- Sort all nodes.
            tree = BinaryHeap.heapify(tree:data())
          end
        else
          neighbor.g = tentative
          neighbor.h = configuration:Heuristic(end_node.point, neighbor.point)
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
