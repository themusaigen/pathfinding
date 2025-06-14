local hash = {}

--- Hashes the point coordinates.
---@param point pathfinding.Vector
---@return string
function hash.hash_point(point)
  return string.format("%d,%d,%d", math.ceil(point.x), math.ceil(point.y), math.ceil(point.z))
end

return hash
