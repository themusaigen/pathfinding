-- File: cache.lua
-- Description: Module that caches the algorithms.
-- Author: themusaigen

local cache = {}

-- The list for replaces in algorithm names.
local possible_replaces = {
  ["*"] = "star"
}

-- The cache of all used algorithms.
---@type pathfinding.Algorithm[]
local algorithms = {}

function cache.convert_algorithm_name(algorithm)
  assert(type(algorithm) == "string")
  assert(#algorithm > 0)

  -- Process a replacings.
  algorithm = algorithm:lower()
  for pattern, replace in pairs(possible_replaces) do
    algorithm = algorithm:gsub(pattern, replace)
  end

  return algorithm
end

--- Caches the algorithm and return it.
---@param algorithm string
---@return pathfinding.Algorithm
function cache.get_algorithm(algorithm)
  -- Convert algorithm name to library format.
  algorithm = cache.convert_algorithm_name(algorithm)

  -- Precache algorithm.
  if not algorithms[algorithm] then
    algorithms[algorithm] = require("pathfinding.algorithm." .. algorithm)
  end

  return algorithms[algorithm]
end

return cache
