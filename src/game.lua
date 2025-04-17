game_states = {}

game_states.Init = {
	enter = function(self)
		font_mitochondria = love.graphics.newFont('assets/fonts/Mitochondria.ttf', 8)
		font_press_start = love.graphics.newFont('assets/fonts/PressStart2P.ttf', 8)
		font_anthurium = love.graphics.newFont('assets/fonts/anthurium.ttf', 16)
		love.graphics.setFont(font_anthurium)

		-- this makes the low res graphics
		love.graphics.setDefaultFilter("nearest", "nearest")
		push:setupScreen(game_width, game_height, window_width, window_height, {fullscreen = false, pixelperfect = true, highdpi = true})
		GOLDEN_RATIO = math.sqrt(2)

		math.randomseed(os.time())

		
	end,

	update = function(self, dt)
		return "CalmPhase"
	end
}

game_states.Menu = {
	enter = function(self)
		
	end, 

	update = function(self, dt)
		return "CalmPhase"
	end
}

game_states.CalmPhase = {
	enter = function(self)
		player = create_captain_player(100, 100)
		local bromeliad1 = create_bromeliad(250, 150)
		local bromeliad2 = create_bromeliad(250, -150)
		for i = 0, 15 do
			local drone = create_drone(200 + math.random(-200, 200), math.random(-200, 200))
			drone.hunger = math.random(10, 25)
			table.insert(creatures, drone)
		end
		table.insert(spawners, create_spawn_pit(212, 50))
		table.insert(creatures, player)
		table.insert(plants, bromeliad1)
		table.insert(plants, bromeliad2)
	end,

	update = function(self, dt)
		update_all_entities(dt)

		-- have camera set position to player
		-- this will have to be changed when introducing game states
		camera:setPosition(math.floor(player.pos.x), math.floor(player.pos.y))
	end,

	draw = function(self)
		push:start()
			camera:draw(draw_all_entities)
		push:finish()
		love.graphics.setBackgroundColor(0.1, 0.1, 0.2, 1)
	end
}

function create_game()
	local game = {
		state_machine = StateMachine.new()
	}
	
	game.state_machine.entity = game
	game.state_machine:add_state("Init", game_states.Init)
	game.state_machine:add_state("Menu", game_states.Menu)
	game.state_machine:add_state("CalmPhase", game_states.CalmPhase)
	game.state_machine:transition_to("Init")

	function game:update(dt)
		-- camera & mouse
		mouse_x, mouse_y = love.mouse.getPosition()
		camera_x, camera_y = camera:getPosition()
		mouse_x = (mouse_x / window_game_ratio)
		mouse_y = (mouse_y / window_game_ratio)
		self.state_machine:update(dt)
	end

	function game:draw()
		self.state_machine:draw()
	end

	return game
end