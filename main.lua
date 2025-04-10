local push = require("lib/push")
require("src/Camera")

require("src/entities/entities")

-- ideally keep main.lua free from any other function definitions other than
-- love.load, love.update, and love.draw

function love.load()
	font_mitochondria = love.graphics.newFont('assets/fonts/Mitochondria.ttf', 8)
	font_press_start = love.graphics.newFont('assets/fonts/PressStart2P.ttf', 8)
	love.graphics.setFont(font_press_start)

	

	-- this makes the low res graphics
	love.graphics.setDefaultFilter("nearest", "nearest")
	push:setupScreen(game_width, game_height, window_width, window_height, {windowed = true, pixelperfect = true, highdpi = true})

	GOLDEN_RATIO = math.sqrt(2)

	math.randomseed(os.time())

	player = create_captain_player(100, 100)
	test_plant = create_bromeliad(250, 150)
	drone1 = create_drone(200, 150)
	drone2 = create_drone(300, 150)
	table.insert(creatures, drone1)
	table.insert(creatures, drone2)
	table.insert(creatures, player)
	table.insert(plants, test_plant)
end



function love.update(dt)
	-- camera & mouse
	mouse_x, mouse_y = love.mouse.getPosition()
	camera_x, camera_y = camera:getPosition()
	mouse_x = (mouse_x / window_game_ratio)
	mouse_y = (mouse_y / window_game_ratio)
	

	update_all(dt)

	-- have camera set position to player
	-- this will have to be changed when introducing game states
	camera:setPosition(math.floor(player.pos.x), math.floor(player.pos.y))
end

--test 5
function love.draw()
	-- include
	push:start()
		camera:draw(draw_all)
	push:finish()
	love.graphics.setBackgroundColor(0.1, 0.3, 0.2, 1)
	
end