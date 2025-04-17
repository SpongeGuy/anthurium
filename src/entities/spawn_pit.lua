local pit_sheet = love.graphics.newImage('assets/sprites/spawners/pit.png')
pit_sheet:setFilter("nearest", "nearest")
local pit_grid = anim8.newGrid(18, 18, pit_sheet:getWidth(), pit_sheet:getHeight())
local pit_animation = anim8.newAnimation(pit_grid('1-1', 1), 1)

function create_spawn_pit(posX, posY)
	local pit = create_new_entity(posX, posY)
	pit.cooldown = 0
	pit.spawn_rate = 10

	function pit:update(dt)
		self.cooldown = math.min(self.spawn_rate, self.cooldown + dt)

		if self.cooldown == self.spawn_rate then
			self.cooldown = 0
			local entity = create_drone(self.pos.x + pit_sheet:getWidth() / 2, self.pos.y + pit_sheet:getHeight() / 2)
			table.insert(creatures, entity)
		end

		self.shake_factor = 1.3 / (1 + 2.718281^(-5* (self.cooldown-(self.spawn_rate-3))))
		print(self.shake_factor)
	end

	function pit:draw()
		love.graphics.push()
			love.graphics.translate(math.floor(self.pos.x), math.floor(self.pos.y))
			
			pit_animation:draw(pit_sheet, math.floor(random_float(0, self.shake_factor)), math.floor(random_float(0, self.shake_factor)), 0, 1, 1)
		love.graphics.pop()
		--love.graphics.print(self.shake_factor, self.pos.x, self.pos.y)
	end


	return pit
end