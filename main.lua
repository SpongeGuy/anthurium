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
end



function love.update(dt)
	m_x, m_y = love.mouse.getPosition()
	m_x = m_x / 4
	m_y = m_y / 4
	player:update(dt)
	for i = #e_utils.bullets, 1, -1 do
		e_utils.bullets[i]:update(dt)
	end
end


--test 5
function love.draw()
	-- include
	push:start()
		player:draw()
		for i = #e_utils.bullets, 1, -1 do
			e_utils.bullets[i]:draw()
		end
		love.graphics.print(player.vel.x, 0, 0)
		love.graphics.print(player.vel.y, 0, 10)
	push:finish()
	
end