StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new()
	machine = {
		entity = {},
		states = {},
		current_state = nil
	}
	return setmetatable(machine, StateMachine)
end

function StateMachine:add_state(state_name, state_obj)
	-- populate a new machine with possible states
	self.states[state_name] = state_obj
end

function StateMachine:transition_to(state_name)
	-- if the current function has an exit function, call it
	if self.current_state and self.current_state.exit then
		self.current_state.exit(self.entity)
	end

	-- transition to next state
	self.current_state = self.states[state_name]

	-- now call the new current state's enter function if it exists
	if self.current_state and self.current_state.enter then
		self.current_state.enter(self.entity)
	end
end

function StateMachine:update(dt)
	-- call the current state's update function if it exists
	local next_state = nil
	if self.current_state and self.current_state.update then
		next_state = self.current_state.update(self.entity, dt)
	end

	-- only transition if the state's update function returns not nil and a valid state_name
	if next_state then
		if self.states[next_state] then
			self:transition_to(next_state)
		else
			error("trying to transition to state which does not exist")
		end
	end
end

function StateMachine:draw()
	if self.current_state and self.current_state.draw then
		self.current_state.draw(self.entity)
	end
end