function create_fruit(posX, posY, dx, dy)
	local fruit = create_new_entity(posX, posY, EntityType.fruit)
	fruit.vel.x = dx
	fruit.vel.y = dy
	fruit.nutrition = 15
	fruit.being_eaten = false
	fruit.collision_cooldown = 0

	function fruit:update(dt)
		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		self.hitbox = {x = self.pos.x - 2, y = self.pos.y - 2, w = 4, h = 4}

		-- bounce other fruits if collision
		local nearby_fruit = SpatialManager:query(self.pos, 25)
		for _, entity in ipairs(nearby_fruit) do
			if self.collision_cooldown == 0 and self ~= entity and entity.entity_type == "fruit" and AABB_collision(self, entity) then
				local normal = get_collision_normal(self, entity)
				local bounce_speed = 35
				self.vel.x = (normal.x + math.random()) * bounce_speed
				self.vel.y = (normal.y + math.random()) * bounce_speed
			end
		end

		local vel_len = math.sqrt(self.vel.x^2 + self.vel.y^2)

		local deceleration = dt * 50

		-- slowly stop fruit from moving
		local epsilon = 0.01
		if vel_len > epsilon then
			local vel_norm_x = self.vel.x / vel_len
			local vel_norm_y = self.vel.y / vel_len
			
			-- apply deceleration in direction of vector
			self.vel.x = self.vel.x - vel_norm_x * (deceleration)
			self.vel.y = self.vel.y - vel_norm_y * (deceleration)
		else
			self.vel.x = 0
			self.vel.y = 0
		end

		
	end

	function fruit:draw()
		love.graphics.setColor(0.4, 0, 0.1)
		love.graphics.circle('fill', self.pos.x-1, self.pos.y-1, 6)
		love.graphics.setColor(0.5, 0.1, 0.1)
		love.graphics.circle('fill', self.pos.x+1, self.pos.y+1, 4)
		love.graphics.setColor(1, 1, 1)
	end

	return fruit
end

function degrees_to_norm_vector(degrees)
	local radians = math.rad(degrees)

	local x = math.cos(radians)
	local y = math.sin(radians)

	local vel_len = math.sqrt(x^2 + y^2)
	if vel_len > 0 then
		x = x / vel_len
		y = y / vel_len
	end
	return {x = x, y = y}
end

local bromeliad_states = {}

bromeliad_states.Fruiting = {
	enter = function(self)
		self.energy = 0
		self.fruit_shoot_degrees = math.random(1, 360)
	end,

	update = function(self, dt)
		-- fruit spawning logic
		self.energy = self.energy + dt
		if self.energy >= self.fruit_spawn_rate then
			-- reset energy to prep to spawn another fruit
			self.energy = 0

			-- determine semi-random shot direction
			local direction = degrees_to_norm_vector(self.fruit_shoot_degrees)
			self.fruit_shoot_degrees = self.fruit_shoot_degrees * GOLDEN_RATIO

			-- launch fruit at random speed (within constraints)
			local random_factor = 50 + math.random() * (75 - 50)
			local fruit = create_fruit(self.pos.x, self.pos.y, direction.x * random_factor, direction.y * random_factor)

			table.insert(collectibles, fruit)
			table.insert(self.fruits, fruit)
		end

		-- stop producing if more than 10 fruits, switch to Idle state
		if #self.fruits > 10 then
			return "Idle"
		end
	end,

	draw = function(self)
		love.graphics.setColor(0.2, 0.7, 0.1)
		love.graphics.circle('fill', self.pos.x, self.pos.y, 10)
		love.graphics.setColor(1, 1, 1)
	end
}

bromeliad_states.Idle = {
	update = function(self, dt)
		-- delete fruits from the plant's personal fruit table if marked
		for i = #self.fruits, 1, -1 do
			local fruit = self.fruits[i]
			if fruit._destroy_this then
				table.remove(self.fruits, i)
			end
		end

		-- check number of fruits after deletion
		if #self.fruits <= 3 then
			return "Fruiting"
		end
	end,

	draw = function(self)
		love.graphics.setColor(0.5, 0.5, 0.1)
		love.graphics.circle('fill', self.pos.x, self.pos.y, 10)
		love.graphics.setColor(1, 1, 1)
	end,
}

function create_bromeliad(posX, posY)
	local plant = create_new_entity(posX, posY, EntityType.fruit_plant)
	plant.energy = 0
	plant.fruit_spawn_rate = 3
	plant.fruits = {}

	-- state machine instantiation
	plant.state_machine:add_state("Fruiting", bromeliad_states.Fruiting)
	plant.state_machine:add_state("Idle", bromeliad_states.Idle)
	plant.state_machine:transition_to("Fruiting")

	function plant:update(dt)
		self.state_machine:update(dt)
		
	end

	function plant:draw()
		self.state_machine:draw()
		
	end
	return plant
end