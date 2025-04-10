-- organization file for entity scripts

require("src/StateMachine")
require("src/SpatialManager")

-- plants
require("src/entities/bromeliad")

-- creatures
require("src/entities/captain")
require("src/entities/drone")

-- used for communication between entities, determines which type of entity
-- set this ideally in the entity creation function
EntityType = {
	fruit_plant = "fruit_plant",
	normal_plant = "normal_plant",
	creature = "creature",
	bullet = "bullet",
	fruit = "fruit",
}

creatures = {}
collectibles = {}
bullets = {}
plants = {}

function update_all(dt)
	for i = #bullets, 1, -1 do
		local bullet = bullets[i]
		bullet:update(dt)
		SpatialManager:update_entity(bullet)
		-- _destroy_this flag
		if bullet._destroy_this then
			table.remove(bullets, i)
			SpatialManager:remove_entity(bullet)
		end
	end

	for i = #creatures, 1, -1 do
		local creature = creatures[i]
		creature:update(dt)
		SpatialManager:update_entity(creature)
		-- _destroy_this flag
		if creature._destroy_this then
			table.remove(creatures, i)
			SpatialManager:remove_entity(creature)
		end
	end

	for i = #collectibles, 1, -1 do
		local collectible = collectibles[i]
		collectible:update(dt)
		SpatialManager:update_entity(collectible)
		-- _destroy_this flag
		if collectible._destroy_this then
			table.remove(collectibles, i)
			SpatialManager:remove_entity(collectible)
		end
	end

	for i = #plants, 1, -1 do
		local plant = plants[i]
		plant:update(dt)
		SpatialManager:update_entity(plant)
		-- _destroy_this flag
		if plant._destroy_this then
			table.remove(plants, i)
			SpatialManager:remove_entity(plant)
		end
	end
end

function draw_all()
	for i = #collectibles, 1, -1 do
		collectibles[i]:draw()
	end
	
	for i = #creatures, 1, -1 do
		creatures[i]:draw()
	end

	for i = #plants, 1, -1 do
		plants[i]:draw()
	end

	for i = #bullets, 1, -1 do
		bullets[i]:draw()
	end
end


-- these functions are bullshit and i don't know where to put them
function approach(current, target, max_change)
	if current < target then
		return math.min(current + max_change, target)
	else
		return math.max(current - max_change, target)
	end
end

function vector_normalize(vector)
	local length = math.sqrt(vector.x^2 + vector.y^2)
	if length == 0 then
		return {x = 0, y = 0}
	else
		return {x = vector.x / length, y = vector.y / length}
	end
end


 

function vector_scalar_multiply(vector, multiplier)
	return {x = vector.x * multiplier, y = vector.y * multiplier}
end