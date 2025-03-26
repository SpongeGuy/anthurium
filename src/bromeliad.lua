local sm = require("src/StateMachine")

function create_fruit(posX, posY, dx, dy)
	local fruit = {
		pos = {x = posX, y = posY},
		vel = {x = dx, y = dy},
	}

	function fruit:update(dt)
		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		-- slowly stop fruit from moving
		if self.vel.x > -0.01 and self.vel.x < 0.01 then
			self.vel.x = 0
		end
		if self.vel.y > 0.01 and self.vel.y < 0.01 then
			self.vel.y = 0
		end

		if self.vel.x > 0 then
			self.vel.x = self.vel.x - dt * 50
		elseif self.vel.x < 0 then
			self.vel.x = self.vel.x + dt * 50
		end

		if self.vel.y > 0 then
			self.vel.y = self.vel.y - dt * 50
		elseif self.vel.y < 0 then
			self.vel.y = self.vel.y + dt * 50
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

	return {x = x, y = y}
end

local bromeliad_states = {}

bromeliad_states.Fruiting = {
	enter = function(self)
		self.energy = 0
	end,

	update = function(self, dt)
		self.energy = self.energy + dt
		if self.energy >= 5 then
			self.energy = 0
			local direction = degrees_to_norm_vector(math.random(0, 359))
			local fruit = create_fruit(self.pos.x, self.pos.y, direction.x * 50, direction.y * 50)
			table.insert(collectibles, fruit)
		end
	end,

	draw = function(self)
		love.graphics.print(self.energy, 0, 0)
	end
}

function create_bromeliad(posX, posY)
	local plant = {
		state_machine = sm.new(),
		pos = {x = posX or 0, y = posY or 0},
		energy = 0 -- used for fruiting
	}
	plant.state_machine.entity = plant
	plant.state_machine:add_state("Fruiting", bromeliad_states.Fruiting)
	plant.state_machine:transition_to("Fruiting")

	function plant:update(dt)
		self.state_machine:update(dt)
	end

	function plant:draw()
		self.state_machine:draw()
		love.graphics.circle('fill', self.pos.x, self.pos.y, 10)
	end
	return plant
end