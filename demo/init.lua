local pathfinding = require("pathfinding")
local Point = pathfinding.Point

local function render_path(path)
  local previous = path[1]
  for i = 2, #path do
    local node = path[i]

    if isPointOnScreen(previous.x, previous.y, previous.z, 0) and isPointOnScreen(node.x, node.y, node.z, 0) then
      local cx, cy = convert3DCoordsToScreen(previous:get())
      local cx1, cy1 = convert3DCoordsToScreen(node:get())

      renderDrawLine(cx, cy, cx1, cy1, 1, -1)
    end

    previous = node
  end
end

local a = nil
local b = nil
local path = nil

function main()
  while not isSampAvailable() do
    wait(0)
  end

  sampRegisterChatCommand("a", function()
    a = Point.new(getCharCoordinates(PLAYER_PED))
  end)

  sampRegisterChatCommand("b", function()
    b = Point.new(getCharCoordinates(PLAYER_PED))
  end)

  sampRegisterChatCommand("path", function()
    if a and b then
      local out = pathfinding:process("a*", a, b)

      if out and #out > 0 then
        path = out
      else
        print("no path")
      end
    end
  end)

  while true do
    wait(0)

    if path then
      render_path(path)
    end
  end
end
