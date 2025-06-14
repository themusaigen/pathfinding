-- File: astar.lua
-- Description: The module that implements A*-based algorithms configuration.
-- Author: themusaigen

---@class pathfinding.AstarConfiguration: pathfinding.Configuration
---@field private _data pathfinding.AstarInterface
---@field check_buildings fun(self: pathfinding.AstarConfiguration, state: boolean) # Sets the state of checking for buildings in collision function.
---@field check_vehicles fun(self: pathfinding.AstarConfiguration, state: boolean) # Sets the state of checking for vehicles in collision function.
---@field check_peds fun(self: pathfinding.AstarConfiguration, state: boolean) # Sets the state of checking for peds in collision function.
---@field check_objects fun(self: pathfinding.AstarConfiguration, state: boolean) # Sets the state of checking for objects in collision function.
---@field check_particles fun(self: pathfinding.AstarConfiguration, state: boolean) # Sets the state of checking for particles in collision function.
---@field check_transparent_objects fun(self: pathfinding.AstarConfiguration, state: boolean) # Sets the state of checking for transparent ojbects in collision function.
---@field ignore_dynamic_objects fun(self: pathfinding.AstarConfiguration, state: boolean) # Sets the state of ignoring for dynamic objects in collision function.
---@field check_shootable_objects fun(self: pathfinding.AstarConfiguration, state: boolean) # Sets the state of checking for shootable through objects in collision function.
local AstarConfiguration = {}
AstarConfiguration.__index = AstarConfiguration

-- Point class.
local Point = require("pathfinding.point")

---@alias pathfinding.Heuristics fun(self: pathfinding.AstarInterface, target: pathfinding.Vector, origin: pathfinding.Vector): number
---@alias pathfinding.Validate fun(self: pathfinding.AstarInterface, point: pathfinding.Vector): boolean
---@alias pathfinding.Collision fun(self: pathfinding.AstarInterface, target: pathfinding.Vector, origin: pathfinding.Vector): boolean
---@alias pathfinding.Neighbors fun(self: pathfinding.AstarInterface, step: number): pathfinding.Vector[]
---@alias pathfinding.IsEndReached fun(self: pathfinding.AstarInterface, end_point: pathfinding.Vector, point: pathfinding.Vector): boolean

---@alias pathfinding.AstarConfiguration.FlagsEnum string | "check_buildings" | "check_vehicles" | "check_peds" | "check_objects" | "check_particles" | "check_transparent_objects" | "ignore_dynamic_objects" | "check_shootable_objects"
---@alias pathfinding.AstarConfiguration.FunctionEnum string | "heuristics" | "validate" | "collision" | "neighbors" | "is_end_reached"
---@alias pathfinding.AstarConfiguration.ValueEnum string | "step" | pathfinding.AstarConfiguration.FunctionEnum | pathfinding.AstarConfiguration.FlagsEnum

---@class pathfinding.AstarInterface
---@field step number
---@field check_buildings boolean
---@field check_vehicles boolean
---@field check_peds boolean
---@field check_objects boolean
---@field check_particles boolean
---@field check_transparent_objects boolean
---@field ignore_dynamic_objects boolean
---@field check_shootable_objects boolean
---@field heuristics pathfinding.Heuristics
---@field validate pathfinding.Validate
---@field collision pathfinding.Collision
---@field neighbors pathfinding.Neighbors
---@field is_end_reached pathfinding.IsEndReached

--- Creates new A*-based configuration.
---@return pathfinding.AstarConfiguration
function AstarConfiguration.new()
	---@type pathfinding.AstarInterface
	local default = {
		step = 1.5,
		check_buildings = true,
		check_vehicles = true,
		check_peds = false,
		check_objects = true,
		check_particles = false,
		check_transparent_objects = false,
		ignore_dynamic_objects = true,
		check_shootable_objects = false,
		heuristics = function(self, target, origin)
			return (target - origin):length()
		end,
		validate = function(self, point)
			return (point.z - getGroundZFor3dCoord(point:get())) <= 2
		end,
		collision = function(self, target, origin)
			return select(
				1,
				processLineOfSight(
					origin.x,
					origin.y,
					origin.z,
					target.x,
					target.y,
					target.z,
					self.check_buildings,
					self.check_vehicles,
					self.check_peds,
					self.check_objects,
					self.check_particles,
					self.check_transparent_objects,
					self.ignore_dynamic_objects,
					self.check_shootable_objects
				)
			)
		end,
		neighbors = function(self, step)
			return {
				Point.new(step),
				Point.new(-step),
				Point.new(0, step),
				Point.new(0, -step),
				Point.new(0, 0, step),
				Point.new(0, 0, -step),

				Point.new(step, step),
				Point.new(-step, -step),
				Point.new(step, -step),
				Point.new(-step, step),
				--
				Point.new(step, step, step),
				Point.new(-step, -step, -step),
				Point.new(-step, step, step),
				Point.new(step, -step, -step),
				Point.new(step, -step, step),
				Point.new(-step, step, -step),
				Point.new(step, step, -step),
				Point.new(-step, -step, step),
				Point.new(step, 0, step),
				Point.new(-step, 0, -step),
			}
		end,
		is_end_reached = function(self, end_point, point)
			return (end_point - point):length() <= self.step
		end,
	}

	return setmetatable({ _data = default }, AstarConfiguration)
end

--- Sets new step.
---@param step number
function AstarConfiguration:set_step(step)
	assert(type(step) == "number")
	assert(step > 0)

	self:set("step", step)
end

-- Generate setters for flags.
local flags = {
	check_buildings = true,
	check_vehicles = true,
	check_peds = true,
	check_objects = true,
	check_particles = true,
	check_transparent_objects = true,
	ignore_dynamic_objects = true,
	check_shootable_objects = true,
}

for name in pairs(flags) do
	AstarConfiguration[name] = function(self, state)
		assert(type(state) == "boolean")

		self:set(name, state)
	end
end

--- Sets new heuristics function.
---@param heuristics pathfinding.Heuristics
function AstarConfiguration:set_heuristics(heuristics)
	assert(type(heuristics) == "function")

	self:set("heuristics", heuristics)
end

--- Sets new validate function.
---@param validate pathfinding.Validate
function AstarConfiguration:set_validate(validate)
	assert(type(validate) == "function")

	self:set("validate", validate)
end

--- Sets new collision function.
---@param collision pathfinding.Collision
function AstarConfiguration:set_collision(collision)
	assert(type(collision) == "function")

	self:set("collision", collision)
end

--- Sets new neighbors function
---@param neighbors pathfinding.Neighbors
function AstarConfiguration:set_neighbors(neighbors)
	assert(type(neighbors) == "function")

	self:set("neighbors", neighbors)
end

--- Sets new end reached check function.
---@param end_reached pathfinding.IsEndReached
function AstarConfiguration:set_end_reached(end_reached)
	assert(type(end_reached) == "function")

	self:set("is_end_reached", end_reached)
end

--- Returns the stored value.
---@param key pathfinding.AstarConfiguration.ValueEnum
---@return any
function AstarConfiguration:get(key)
	assert(type(key) == "string")
	assert(#key > 0)

	return self._data[key]
end

--- Store some value.
---@param key pathfinding.AstarConfiguration.ValueEnum
---@param value any
function AstarConfiguration:set(key, value)
	assert(type(key) == "string")
	assert(#key > 0)

	self._data[key] = value
end

--- Calls the stored function.
---@param key pathfinding.AstarConfiguration.FunctionEnum
---@param ... any
function AstarConfiguration:call(key, ...)
	-- Get the function.
	---@type function
	local fun = self:get(key)
	assert(type(fun) == "function")

	-- Call the function.
	return fun(self._data, ...)
end

return AstarConfiguration
