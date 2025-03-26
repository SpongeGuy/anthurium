local sm = require("src/StateMachine")

function spawn_fruit(posX, posY, dx, dy)
	local fruit = {
		pos = {x = posX, y = posY},
		vel = {x = dx, y = dy},
	}

	function fruit:update(dt)
		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt
	end

	return fruit
end

local bromeliad_states = {}

bromeliad_states.Fruiting = {
	enter = function(self)
		self.energy = 0
	end,

	update = function(self, dt)
		self.energy = self.energy + dt
		print(self.energy)
		if self.energy >= 5 then
			self.energy = 0
			print("FRUIT")
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