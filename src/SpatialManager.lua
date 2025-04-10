SpatialManager = {
	grid = {},
	cell_size = 50
}

function SpatialManager:get_cell_key(position)
	local x_index = math.floor(position.x / self.cell_size)
	local y_index = math.floor(position.y / self.cell_size)
	return x_index .. "_" .. y_index
end

function SpatialManager:register_entity(entity)
	-- register an entity using this in an entity create function
	local key = self:get_cell_key(entity.pos)
	if not self.grid[key] then
		self.grid[key] = {}
	end
	table.insert(self.grid[key], entity)
	entity._spatial_key = key
end

function SpatialManager:update_entity(entity)
	local new_key = self:get_cell_key(entity.pos)
	if new_key ~= entity._spatial_key then
		-- remove from old cell
		self:remove_entity(entity)
		-- add to new cell
		self:register_entity(entity)
	end
end

function SpatialManager:remove_entity(entity)
	local cell = self.grid[entity._spatial_key]
	if cell then
		for i, ent in ipairs(cell) do
			if ent == entity then
				table.remove(cell, i)
				break
			end
		end
	end
end

-- will return a list of entities around a radius from a {x, y} coordinate using the spatial grid
function SpatialManager:query(position, radius)
	local results = {}
	local min_x = math.floor((position.x - radius) / self.cell_size)
	local max_x = math.floor((position.x + radius) / self.cell_size)
	local min_y = math.floor((position.y - radius) / self.cell_size)
	local max_y = math.floor((position.y + radius) / self.cell_size)

	for x = min_x, max_x do
		for y = min_y, max_y do
			local key = x .. "_" .. y
			if self.grid[key] then
				for _, entity in ipairs(self.grid[key]) do
					table.insert(results, entity)
				end
			end
		end
	end
	return results
end