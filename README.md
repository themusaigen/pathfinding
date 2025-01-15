# pathfinding

Library for implementing pathfinding algorithms in GTA:SA.
This means that this library does not seek to implement only one pathfinding algorithm, but several, trying to bring them to a "usable" state. At the moment, work is underway on the most well-known and easy-to-implement algorithm A*.

## Installation

Clone the repository and extract `src` directory content to the `moonloader/lib` directory.

## Usage / Demo

See basic example of usage in `demo/init.lua` file. You also can extract `demo/init.lua` to your `moonloader` directory and test library right in the game.

## Overview

* `[...]` - required parameter.
* `(...)` - optional parameter.

`pathfinding` exports one main function:

```lua
local path = pathfinding:process([algorithm-name: string], [start: Vector], [goal: Vector], (configuration: Configuration|nil))
```

1. As you can see, the first argument is the name of the algorithm, it can be either `a*` or `astar` (case is not important). Required.
2. The second argument is the vector of the starting point and the vector of the ending point. They have a special Vector class. In order to get it, you need the Point class, which is included with the Pathfinding table. Required. Examples:
```lua
-- Case 1:
local Point = pathfinding.Point

-- Case 2:
local Point = require("pathfinding.point")

-- Case 3: (Yea, Point and core Vector3d classes are same, but Point provides some utility in consturcting)
local Vector3D = require("vector3d") -- moonloader/lib/vector3d

-- Use case:
local pointA = Point.new(1, 2) -- It is not necessary to specify all the coordinates, but the order is important.

local pointB = Vector3D(3, 4, 5)
```
3. The third argument is the configuration for the algorithm, which affects its outcome. In fact, it's just a table with some parameters. Optional.
```lua
-- Every parameter is optional, library replaces the missing parameters with default parameters. 
local default_configuration = {
  -- The larger the step, the lower the RAM costs, and the algorithm will run faster, but it will be less accurate.
  Step = 1.5,
  -- A heuristic function, by default it is the distance from one node to another.
  Heuristics = function(self, node0: Node, node1: Node)
    return (node0.point - node1.point):length()
  end,
  -- The coordinate vector validation function. In this function, you can check for height differences and generally check whether this point is achievable. Used when creating a list of neighbors.
  Validate = function(self, point: Vector)
    return (point - getGroundZFor3dCoord(point:get())) <= 5
  end,
  -- A function for checking for obstacles between two points. Returns true if there are no obstacles and false if there are. Used when creating a list of neighbors.
  Collision = function(self, target: Vector, origin: Vector)
    return isLineOfSightClear(target, origin, ...)
  end,
  -- A function that returns a list of points for potential neighbors. The more points, the more accurate the path, but the higher the cost of RAM and speed. Used when creating a list of neighbors. By default there is 20+ points.
  Neighbors = function(self, step: number)
    return {
      Point.new(...),
      -- other points
    }
  end
}
```
4. The algorithm "spits out" a list of points of the Vector class. If the path is unreachable, the list will be empty.

## References
* [A* (RU)](https://ru.wikipedia.org/wiki/A*)
* [A* (EN)](https://en.wikipedia.org/wiki/A*_search_algorithm)

## See also

* `pathfinding` written using [moonly](github.com/themusaigen/moonly)

## License

`pathfinding` licensed under `MIT License`. See `LICENSE` for details.