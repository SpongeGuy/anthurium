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
	bromeliad1 = create_bromeliad(250, 150)
	bromeliad2 = create_bromeliad(250, -150)
	for i = 0, 25 do
		local drone = create_drone(250 + math.random(0, 10), math.random(-10, 10))
		drone.hunger = math.random(-5, 10)
		table.insert(creatures, drone)
	end
	table.insert(creatures, player)
	table.insert(plants, bromeliad1)
	table.insert(plants, bromeliad2)
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