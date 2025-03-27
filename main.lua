local push = require("lib/push")
local game_width, game_height = 480, 270
local window_width, window_height = love.window.getDesktopDimensions()

local e_utils = require("src/entities")

font_mitochondria = love.graphics.newFont('assets/fonts/Mitochondria.ttf', 8)
font_press_start = love.graphics.newFont('assets/fonts/PressStart2P.ttf', 8)
love.graphics.setFont(font_press_start)

-- this makes the low res graphics
love.graphics.setDefaultFilter("nearest", "nearest")
push:setupScreen(game_width, game_height, window_width, window_height, {fullscreen = true, pixelperfect = true, highdpi = true})

GOLDEN_RATIO = math.sqrt(2)

math.randomseed(os.time())

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

function approach(current, target, max_change)
	if current < target then
		return math.min(current + max_change, target)
	else
		return math.max(current - max_change, target)
	end
end

require("src/bromeliad")

function love.load()
	player = e_utils:create_captain_player(100, 100)
	test_plant = create_bromeliad(300, 50)
	table.insert(creatures, player)
	table.insert(plants, test_plant)
end



function love.update(dt)
	m_x, m_y = love.mouse.getPosition()
	m_x = m_x / 4
	m_y = m_y / 4


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


--test 5
function love.draw()
	-- include
	push:start()
		
		
		for i = #bullets, 1, -1 do
			bullets[i]:draw()
		end
		for i = #creatures, 1, -1 do
			creatures[i]:draw()
		end
		for i = #collectibles, 1, -1 do
			collectibles[i]:draw()
		end
		for i = #plants, 1, -1 do
			plants[i]:draw()
		end
	push:finish()
	
end