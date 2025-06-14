-- File: heap.lua
-- Description: A implementation of the binary heap class for pathfinding algorithms.
-- Author: themusaigen

---@class pathfinding.BinaryHeap
---@field private _data table
---@field private _size number
---@field private _indices {[string]: number}
local BinaryHeap = {}
BinaryHeap.__index = BinaryHeap

--- Creates new `Heap` class instance.
---@return pathfinding.BinaryHeap
function BinaryHeap.new()
	return setmetatable({ _data = {}, _indices = {}, _size = 0 }, BinaryHeap)
end

local function sift_up(heap, index)
	while index > 1 do
		local parent = math.floor(index / 2)
		if heap:get(index) < heap:get(parent) then
			-- Update hashes.
			heap._indices[tostring(heap._data[parent])] = index
			heap._indices[tostring(heap._data[index])] = parent

			-- Swap elements.
			heap._data[parent], heap._data[index] = heap._data[index], heap._data[parent]

			-- Next element.
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
			-- Update hashes.
			heap._indices[tostring(heap._data[smallest])] = index
			heap._indices[tostring(heap._data[index])] = smallest

			-- Swap elements.
			heap._data[smallest], heap._data[index] = heap._data[index], heap._data[smallest]

			-- Next element.
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
	self._size = self._size + 1
	self._indices[tostring(value)] = self._size
	sift_up(self, self._size)
end

--- Resortes the already stored value in heap.
---@param index integer
---@return boolean # Is we succesfully resorted that element.
function BinaryHeap:resort(index)
	local value = self:get(index)
	if not value then
		return false
	end

	if index > 1 and value < self:get(math.floor(index / 2)) then
		sift_up(self, index)
	else
		sift_down(self, index)
	end

	return true
end

--- Removes the first element in the Heap and returns it
---@return any
function BinaryHeap:pop()
	if self._size == 0 then
		return
	end

	local out = self._data[1]
	local last = self._data[self._size]

	self._indices[tostring(out)] = nil
	self._indices[tostring(last)] = 1

	self._data[1] = last

	table.remove(self._data, self._size)
	self._size = self._size - 1
	if #self > 0 then
		sift_down(self, 1)
	end

	return out
end

--- Returns the index of a given element in the heap.
---
--- This function converts the element to a string and uses it as a hash key
--- to look up the position in the internal `_indices` table.
---
---@param element any # The element to find in the heap.
---@return integer # The 1-based index of the element if found, or -1 if not found.
function BinaryHeap:index_of(element)
	return self:index_of_by_hash(tostring(element))
end

--- Returns the index of an element using its hash as a lookup key.
---
--- This is an internal helper method that searches for the element's index
--- by checking the `_indices` map directly.
---
---@param hash string # The hash key used to identify the element.
---@return integer # The 1-based index of the element if found, or -1 if not found.
function BinaryHeap:index_of_by_hash(hash)
	return self._indices[hash] or -1
end

--- Converts a table to a Heap. Will destroy the provided table
---@param list table
---@return pathfinding.BinaryHeap
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
	return self._size
end

return BinaryHeap
