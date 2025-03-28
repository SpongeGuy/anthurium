-- organization file for entity scripts

sm = require("src/StateMachine")

-- plants
require("src/entities/bromeliad")

-- creatures
require("src/entities/captain")

creatures = {}
collectibles = {}
bullets = {}
plants = {}

function update_all(dt)
	for i = #bullets, 1, -1 do
		local bullet = bullets[i]
		bullet:update(dt)
		-- destroy_this flag
		if bullet.destroy_this then
			table.remove(bullets, i)
		end
	end

	for i = #creatures, 1, -1 do
		local creature = creatures[i]
		creature:update(dt)
		-- destroy_this flag
		if creature.destroy_this then
			table.remove(creatures, i)
		end
	end

	for i = #collectibles, 1, -1 do
		local collectible = collectibles[i]
		collectible:update(dt)
		-- destroy_this flag
		if collectible.destroy_this then
			table.remove(collectibles, i)
		end
	end

	for i = #plants, 1, -1 do
		local plant = plants[i]
		plant:update(dt)
		-- destroy_this flag
		if plant.destroy_this then
			table.remove(plants, i)
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