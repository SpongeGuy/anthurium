-- creature template example



-- imagine each state as a node in a graph
-- each node can have connections to other nodes

local template_states = {}

template_states.GetMoney = {
	enter = function(self)
		-- called once when entering state
		-- here you can even define (and reset) variables
		self.cash_register_value = 0
	end

	update = function(self, dt) 
		-- called every frame when state is active
		if condition then
			self.cash_register_value = self.cash_register_value + 1
		end
		if self.cash_register_value >= 100 then
			return "Chill"
		end
	end

	draw = function(self)
		-- called every frame when state is active
	end

	exit = function(self)
		-- called once when exiting state
	end
}

template_states.Chill = {
	update = function(self, dt)
		if jester_present then
			return "GetMoney"
		else
			print("we're chilling")
		end
	end
}

-- define actual creature

function create_template(posX, posY, dx, dy)
	-- define/instantiate variables
	local template = {
		state_machine = sm.new(),
		pos = {x = posX, y = posY},
		vel = {x = dx, y = dy},
		_destroy_this = false, -- this one is optional, but _destroy_this is a reserved value for deleting entities
	}

	-- state machine boiler plate (necessary)
	template.state_machine.entity = template
	template.state_machine:add_state("GetMoney", template_states.GetMoney)
	template.state_machine:add_state("Chill", template_states.Chill)
	template.state_machine:transition_to("GetMoney")

	function template:update(dt)
		-- call the state machine's update function
		self.state_machine:update(dt)
		-- include anything here which should always update no matter the entity's state
	end

	function template:draw()
		-- call the state machine's update function
		self.state_machine:draw()
		-- include anything here which should always be drawn no matter the entity's state
	end

	-- don't forget to return the entity otherwise wtf are u doing
	return template
end