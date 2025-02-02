-- File: dynamic.lua
-- Description: Module that dynamically builds the path.
-- Author: themusaigen

---@class pathfinding.DynamicPathBuilder
---@field private algorithm pathfinding.Algorithm|nil
---@field private start pathfinding.Vector|nil
---@field private goal pathfinding.Vector|nil
---@field private configuration pathfinding.Configuration|nil
---@field private delay integer
---@field private path pathfinding.Vector[]
---@field private path_dynamic pathfinding.Vector[]
---@field private path_thread LuaThread
local DynamicPathBuilder = {}
DynamicPathBuilder.__index = DynamicPathBuilder

-- Point class.
local Point = require("pathfinding.point")

-- Module for caching algorithms.
local cache = require("pathfinding.cache")

-- Utilities.
local utility = require("pathfinding.utility")

--- Creates new dynamic path builder.
---@param algorithm string|nil
---@param start pathfinding.Vector|nil
---@param goal pathfinding.Vector|nil
---@param configuration pathfinding.Configuration|nil
---@return pathfinding.DynamicPathBuilder
function DynamicPathBuilder.new(algorithm, start, goal, configuration)
  if algorithm then
    assert(type(algorithm) == "string")
    assert(#algorithm > 0)
  end

  if start then
    assert(type(start) == "table")
  end

  if goal then
    assert(type(goal) == "table")
  end

  if configuration then
    assert(type(configuration) == "table")
  end

  return setmetatable({
    algorithm = algorithm and cache.get_algorithm(algorithm),
    start = start,
    goal = goal,
    configuration = configuration,

    -- Delay between iterations.
    delay = 0,

    -- Separate thread for path calculation.
    path_thread = nil,

    -- The original path.
    path = nil,

    -- The path that was changed due to collisions with obstacles.
    path_dynamic = nil,
  }, DynamicPathBuilder)
end

--- Sets the delay between iterations for updating the path.
---@param delay integer
function DynamicPathBuilder:set_delay(delay)
  assert(type(delay) == "number")
  assert(delay % 1 == 0)
  assert(delay > 0)

  self.delay = delay
end

--- Enables the path builder.
function DynamicPathBuilder:enable()
  assert(self.algorithm)
  assert(self.start)
  assert(self.goal)
  assert(self.configuration)

  -- To implement dynamic pathfinding, we need to use the collision method to account only for buildings as obstacles.
  local collision_backup = self.configuration:get("collision")
  self.configuration:set("collision", function(_, target, origin)
    return isLineOfSightClear(origin.x, origin.y, origin.z, target.x, target.y, target.z, true, false, false, false,
      false)
  end)

  -- Create new path.
  self.path = self.algorithm:process(self.start, self.goal, self.configuration)

  -- Restore backup.
  self.configuration:set("collision", collision_backup)

  -- If thread already created then run it.
  if self.path_thread then
    return self.path_thread:run()
  end

  local function process_line_of_sight(a, b)
    return processLineOfSight(a.x, a.y, a.z, b.x, b.y, b.z, self.configuration:get("check_buildings"),
      self.configuration:get("check_vehicles"), self.configuration:get("check_peds"),
      self.configuration:get("check_objects"), self.configuration:get("check_particles"),
      self.configuration:get("check_transparant_objects"), self.configuration:get("ignore_dynamic_objects"),
      self.configuration:get("check_shootable_objects"))
  end

  local function get_max_dimension_of_entity(entity_type, entity)
    local x1, y1, z1, x2, y2, z2 = 0, 0, 0, 0, 0, 0
    if entity_type == 1 then
      ---@diagnostic disable-next-line: param-type-mismatch
      x1, y1, z1, x2, y2, z2 = getModelDimensions(readMemory(entity + 0x22, 0x2, true))
    elseif entity_type == 2 then
      ---@diagnostic disable-next-line: param-type-mismatch
      x1, y1, z1, x2, y2, z2 = getModelDimensions(getCarModel(getVehiclePointerHandle(entity)))
    elseif entity_type == 3 then
      x1, y1, z1, x2, y2, z2 = getModelDimensions(getCharModel(getCharPointerHandle(entity)))
    elseif entity_type == 4 then
      x1, y1, z1, x2, y2, z2 = getModelDimensions(getObjectModel(getObjectPointerHandle(entity)))
    else
      return 2.5
    end
    local width = math.abs(x2 - x1)
    local length = math.abs(y2 - y1)
    local height = math.abs(z2 - z1)
    return math.max(width, length, height)
  end

  local function shift_point_at_free_space(point, direction)
    local result, colpoint = process_line_of_sight(point, point + Point.new(0, 0, 0.5))
    if result then
      point = point + direction * get_max_dimension_of_entity(colpoint.entityType, colpoint.entity)
      return shift_point_at_free_space(point)
    else
      return point
    end
  end

  local function get_free_point_avoiding_obstacles(a, b)
    local result, colpoint = process_line_of_sight(a, b)
    if result then
      local max_dimension = get_max_dimension_of_entity(colpoint.entityType, colpoint.entity)
      local colpos = Point.new(colpoint.pos)

      local direction = b - a
      direction:normalize()
      local reversed_direction = a - b
      reversed_direction:normalize()

      local free_point = shift_point_at_free_space(colpos + direction * max_dimension, reversed_direction)
      local result1, colpoint1 = process_line_of_sight(free_point, colpos)

      if result1 then
        return Point.new(colpoint1.pos) + direction * 2.5
      else
        return free_point
      end
    else
      return b
    end
  end

  local function get_nearest_point_in_list(list, point)
    local minimal_distance, nearest = math.huge, -1
    for index, value in ipairs(list) do
      local distance = (value - point):length()
      if distance < minimal_distance then
        minimal_distance, nearest = distance, index
      end
    end
    return nearest
  end

  -- Create new thread for updating.
  self.path_thread = lua_thread.create_suspended(function()
    while true do
      assert(self.algorithm)
      assert(self.start)
      assert(self.goal)
      assert(self.configuration)
      assert(self.delay > 0)

      local length = #self.path
      if length > 0 then
        -- Creating a table for the new dynamic path.
        local path = {}

        -- A flag to check if there were any obstacles on the way.
        local have_collisions = false

        -- Start.
        local index = 1
        while (index <= (length - 1)) do
          local point = self.path[index]
          local next_point = self.path[index + 1]

          -- No collisions, just set the points.
          if self.configuration:call("collision", next_point, point) then
            path[#path + 1] = point

            -- Go to the next pair of points.
            index = index + 1
          else
            -- Acquired collisions.
            have_collisions = true

            -- We will get the direction towards the first point.
            local direction = (point - next_point)
            direction:normalize()

            -- We shift the position of the point into a space where there are no obstacles.
            point = shift_point_at_free_space(point, direction)

            -- Now, considering all the obstacles, we have to find an free point in the direction of the path.
            local free_point = get_free_point_avoiding_obstacles(point, next_point)

            -- Rebuild the path between this points.
            local rebuilt_path = self.algorithm:process(point, free_point, self.configuration)

            -- If path succesfully rebuilt.
            if #rebuilt_path > 0 then
              -- Add new points.
              utility.traverse(rebuilt_path, function(_, value)
                table.insert(path, value)
              end)

              -- Get point that nearest to our last added point.
              local nearest_to_end_index = get_nearest_point_in_list(self.path, path[#path])

              -- No infinty loops.
              if (nearest_to_end_index <= index) then
                nearest_to_end_index = index + 1
              end

              -- Switch to the next point.
              index = nearest_to_end_index
            else
              break
            end
          end

          -- If the new path is longer or the same as the old one, or there were...
          -- ..no collisions on the way. Then we update the dynamic path.
          if (#path >= length) or (not have_collisions) then
            self.path_dynamic = path
          end
        end
      end


      -- Wait for next iteration.
      wait(self.delay)
    end
  end)
  self.path_thread:run()
end

--- Sets the new algorithm.
---@param algorithm string
function DynamicPathBuilder:set_algorithm(algorithm)
  self.algorithm = cache.get_algorithm(algorithm)
end

--- Returns the current algorithm.
---@return pathfinding.Algorithm
function DynamicPathBuilder:get_algorithm()
  return self.algorithm
end

--- Sets the new start point.
---@param start pathfinding.Vector
function DynamicPathBuilder:set_start_point(start)
  assert(type(start) == "table")

  self.start = start
end

--- Returns the start point.
---@return pathfinding.Vector
function DynamicPathBuilder:get_start_point()
  return self.start
end

--- Sets the new goal point.
---@param goal pathfinding.Vector
function DynamicPathBuilder:set_goal_point(goal)
  assert(type(goal) == "table")

  self.goal = goal
end

--- Returns the goal point.
---@return pathfinding.Vector
function DynamicPathBuilder:get_goal_point()
  return self.goal
end

--- Sets the new configuration.
---@param configuration pathfinding.Configuration
function DynamicPathBuilder:set_configuration(configuration)
  assert(type(configuration) == "table")

  self.configuration = configuration
end

--- Returns current configuration.
---@return pathfinding.Configuration
function DynamicPathBuilder:get_configuration()
  return self.configuration
end

--- Disables the path builder.
function DynamicPathBuilder:disable()
  assert(self.path_thread, "First turn on DynamicPathBuilder before turning it off.")

  -- Terminate (suspend) the thread.
  self.path_thread:terminate()
end

--- Returns the builded path.
---@return pathfinding.Vector[]
function DynamicPathBuilder:get_path()
  return self.path_dynamic and self.path_dynamic or self.path
end

--- Returns is path builder running now.
---@return boolean
function DynamicPathBuilder:running()
  return self.path_thread and ((self.path_thread:status() == "running") or (self.path_thread:status() == "yielded"))
end

return DynamicPathBuilder
