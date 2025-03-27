local sm = require("src/StateMachine")

function create_fruit(posX, posY, dx, dy)
	local fruit = {
		pos = {x = posX, y = posY},
		vel = {x = dx, y = dy},
		destroy_this = false,
	}

	function fruit:update(dt)
		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		local vel_len = math.sqrt(self.vel.x^2 + self.vel.y^2)

		local deceleration = dt * 50

		-- slowly stop fruit from moving
		local epsilon = 0.01
		if vel_len > epsilon then
			local vel_norm_x = self.vel.x / vel_len
			local vel_norm_y = self.vel.y / vel_len
			-- apply deceleration
			
			self.vel.x = self.vel.x - vel_norm_x * (deceleration)
			self.vel.y = self.vel.y - vel_norm_y * (deceleration)
		else
			self.vel.x = 0
			self.vel.y = 0
		end
	end

	function fruit:draw()
		love.graphics.circle('fill', self.pos.x-1, self.pos.y-1, 5)
		love.graphics.circle('fill', self.pos.x+1, self.pos.y+1, 5)
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
		self.energy = self.energy + dt
		if self.energy >= 0.5 then
			self.energy = 0
			local direction = degrees_to_norm_vector(self.fruit_shoot_degrees)
			self.fruit_shoot_degrees = self.fruit_shoot_degrees * math.sqrt(2)
			local random_factor = 25 + math.random() * (75 - 25)
			local fruit = create_fruit(self.pos.x, self.pos.y, direction.x * random_factor, direction.y * random_factor)
			table.insert(collectibles, fruit)
			table.insert(self.fruits, fruit)
		end
		if #self.fruits > 10 then
			print("hi")
			return "Idle"
		end
	end,

	draw = function(self)
		love.graphics.print(self.energy, 0, 0)
		love.graphics.setColor(0.2, 0.7, 0.1)
		love.graphics.circle('fill', self.pos.x, self.pos.y, 10)
		love.graphics.setColor(1, 1, 1)
	end
}

bromeliad_states.Idle = {
	update = function(self, dt)
		if #self.fruits < 3 then
			return "Fruiting"
		end
	end,

	draw = function(self)

	end,
}

function create_bromeliad(posX, posY)
	local plant = {
		state_machine = sm.new(),
		pos = {x = posX or 0, y = posY or 0},
		energy = 0, -- used for fruiting
		fruits = {},
	}
	plant.state_machine.entity = plant
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