local push = require("lib/push")
local game_width, game_height = 480, 270
local window_width, window_height = love.window.getDesktopDimensions()

require("src/entities/entities")

-- ideally keep main.lua free from any other function definitions other than
-- love.load, love.update, and love.draw

function love.load()
	font_mitochondria = love.graphics.newFont('assets/fonts/Mitochondria.ttf', 8)
	font_press_start = love.graphics.newFont('assets/fonts/PressStart2P.ttf', 8)
	love.graphics.setFont(font_press_start)

	-- this makes the low res graphics
	love.graphics.setDefaultFilter("nearest", "nearest")
	push:setupScreen(game_width, game_height, window_width, window_height, {fullscreen = true, pixelperfect = true, highdpi = true})

	GOLDEN_RATIO = math.sqrt(2)

	math.randomseed(os.time())

	player = create_captain_player(100, 100)
	test_plant = create_bromeliad(250, 150)
	drone = create_drone(150, 100)
	table.insert(creatures, drone)
	table.insert(creatures, player)
	table.insert(plants, test_plant)
end



function love.update(dt)
	m_x, m_y = love.mouse.getPosition()
	m_x = m_x / 4
	m_y = m_y / 4

	update_all(dt)
end


--test 5
function love.draw()
	-- include
	push:start()
		draw_all()
	push:finish()
	love.graphics.setBackgroundColor(0.1, 0.3, 0.2, 1)
end