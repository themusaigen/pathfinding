-- File: heap.lua
-- Description: A implementation of the binary heap class for pathfinding algorithms.
-- Author: themusaigen

---@class BinaryHeap
---@field private _data table
local BinaryHeap = {}
BinaryHeap.__index = BinaryHeap

--- Creates new `Heap` class instance.
---@return BinaryHeap
function BinaryHeap.new()
  return setmetatable({ _data = {} }, BinaryHeap)
end

local function sift_up(heap, index)
  while (index > 1) do
    local parent = math.floor(index / 2)
    if heap:get(index) < heap:get(parent) then
      heap._data[parent], heap._data[index] = heap._data[index], heap._data[parent]

      index = parent
    else
      break
    end
  end
end

local function sift_down(heap, index)
  while true do
    local left = index * 2
    local right = index * 2 + 1
    local smallest = index

    if left <= #heap and (heap:get(left) < heap:get(smallest)) then
      smallest = left
    end

    if right <= #heap and (heap:get(right) < heap:get(smallest)) then
      smallest = right
    end

    if not (smallest == index) then
      heap._data[smallest], heap._data[index] = heap._data[index], heap._data[smallest]
      index = smallest
    else
      break
    end
  end
end

--- Adds an element to the Heap
---@param value any
function BinaryHeap:push(value)
  table.insert(self._data, value)

  if #self <= 1 then
    return
  end

  sift_up(self, #self)
end

--- Removes an element from heap.
---@param idx integer
function BinaryHeap:remove(idx)
  assert(type(idx) == "number")
  assert(idx % 1 == 0)
  assert(#self >= idx)

  -- Remove element from list.
  table.remove(self._data, idx)
end

--- Removes an element from heap and replaces it with new one.
---@param idx integer
---@param value any
function BinaryHeap:repush(idx, value)
  self:remove(idx)
  self:push(value)
end

--- Removes the first element in the Heap and returns it
---@return any
function BinaryHeap:pop()
  if #self > 0 then
    local out = self:get(1)
    self._data[1] = self:get(#self)
    table.remove(self._data, #self._data)

    if #self > 0 then
      sift_down(self, 1)
    end

    return out
  end
end

--- Converts a table to a Heap. Will destroy the provided table
---@param list table
---@return BinaryHeap
function BinaryHeap.heapify(list)
  assert(type(list) == "table")

  local heap = BinaryHeap.new()
  for i = #list, 1, -1 do
    heap:push(list[i])
    table.remove(list, i)
  end
  return heap
end

--- Returns the value stored at specific index.
---@param index integer
---@return any
function BinaryHeap:get(index)
  assert(type(index) == "number")
  assert(index % 1 == 0)
  assert(index > 0)
  return self._data[index]
end

--- Returns data table.
---@return table
function BinaryHeap:data()
  return self._data
end

--- Returns the length of list
---@return integer
function BinaryHeap:__len()
  return #self._data
end

return BinaryHeap
