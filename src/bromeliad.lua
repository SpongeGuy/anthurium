local sm = require("src/StateMachine")

local bromeliad_states = {}

bromeliad_states.Fruiting = {
	enter = function(self)
		self.energy = 0
	end,

	update = function(self, dt)

	end,
}

function create_bromeliad(posX, posY)
	local plant = {
		state_machine = sm.new(),
		pos = {x = posX or 0, y = posY or 0},
		energy = 0 -- used for fruiting
	}
	plant.state_machine:add_state("Fruiting", bromeliad_states.Fruiting)
	plant.state_machine:transition_to("Fruiting")

end