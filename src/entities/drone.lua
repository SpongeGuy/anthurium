-- drone simple behavior
-- when hungry
-- - seek out plant, then fruit
-- when not hungry
-- - wander randomly
-- when near a creature
-- - point towards it and begin attacking
-- when attacking
-- - point towards assailant and do damage, move back and forth

function get_random_coordinate_away(x, y, dist)
	-- create a vector away from a set of coordinates
	local random_angle = math.random() * (2 * math.pi)
	local nx = x + dist * math.cos(random_angle)
	local ny = y + dist * math.sin(random_angle)
	return {x = nx, y = ny}

end

function get_random_coordinate_away_range(x, y, dist, min_degrees, max_degrees)
	-- create a vector away from a set of coordinates
	local min_radians = math.rad(min_degrees)
	local max_radians = math.rad(max_degrees)
	local random_angle = min_radians + math.random() * (max_radians - min_radians)
	local nx = x + dist * math.cos(random_angle)
	local ny = y + dist * math.sin(random_angle)
	return {x = nx, y = ny}

end

function vector_to_degrees(vector)
	local angle_radians = math.atan2(vector.y, vector.x)
	local angle_degrees = math.deg(angle_radians)
	return angle_degrees
end

function draw_bouncy_exclamation_mark(x, y, timer)
	local A = 25
	local l = 0.5
	local e = 2.71828
	local h = 0.9
	local B = 1.5
	-- bouncy exclamation mark equation
	love.graphics.print("!", math.floor(x) - 1, math.floor(y - (A*e^(-l*(timer^h)) * math.abs(math.sin(B*timer))) - 7))
end

local drone_states = {}

drone_states.Wandering = {
	enter = function(self)
		-- create a node between 100 and 20 units away from the x, y
		local dist = 20 + math.random() * 40
		self.move_node = get_random_coordinate_away(self.pos.x, self.pos.y, dist)

		-- set velocity towards move_node
		self.vel = vector_normalize({x = self.move_node.x - self.pos.x, y = self.move_node.y - self.pos.y})
		self.vel = {x = self.vel.x * 25, y = self.vel.y * 25}
		self.move_branches = math.random(0, 4)

	end,

	update = function(self, dt)
		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		-- visual bullshit
		if self.size < 4 then
			self.size = 6
		end
		self.size = self.size - dt * 6

		-- node reach logic
		local epsilon = 1
		if math.abs(self.pos.x - self.move_node.x) <= epsilon and math.abs(self.pos.y - self.move_node.y) <= epsilon then
			if self.move_branches <= 0 then
				return "Waiting"
			else
				-- decrement amount of nodes to create
				self.move_branches = self.move_branches - 1

				local dist = 20 + math.random() * 160
				local degrees = vector_to_degrees(self.vel)
				local min_degrees = degrees - 50
				local max_degrees = degrees + 50
				self.move_node = get_random_coordinate_away_range(self.pos.x, self.pos.y, dist, min_degrees, max_degrees)

				-- set velocity towards move_node
				self.vel = vector_normalize({x = self.move_node.x - self.pos.x, y = self.move_node.y - self.pos.y})
				self.vel = {x = self.vel.x * 25, y = self.vel.y * 25}
			end
		end

		-- search for other creature logic
		for i = #creatures, 1, -1 do
			local creature = creatures[i]
			if creature ~= self then
				local distX = creature.pos.x - self.pos.x
				local distY = creature.pos.y - self.pos.y
				local dist_sq = distX*distX + distY*distY
				if dist_sq <= self.aggro_range ^2 then
					self.target = creature
					return "Pursuing"
				end
			end
		end
	end,

	draw = function(self)
		--love.graphics.circle('fill', self.move_node.x, self.move_node.y, 1)
		--love.graphics.line(self.pos.x, self.pos.y, self.pos.x + self.vel.x, self.pos.y + self.vel.y)
	end
}

drone_states.Waiting = {
	enter = function(self)
		
		self.timer = 0
		self.random_wait_value = math.random(2, 5)
		self.size = 5
	end,

	update = function(self, dt)
		-- slow down velocity smoothly
		if math.abs(self.vel.x) > 0 or math.abs(self.vel.y) > 0 then
			self.vel.x = self.vel.x / 1.02
			self.vel.y = self.vel.y / 1.02
			if math.abs(self.vel.x) < 1 then
				self.vel.x = 0
			end
			if math.abs(self.vel.y) < 1 then
				self.vel.y = 0
			end
		end

		-- update position based on velocity
		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		self.timer = self.timer + dt
		self.size = (math.sin(self.timer)) + 4
		if self.timer > self.random_wait_value then
			return "Wandering"
		end

		-- search for other creature logic
		for i = #creatures, 1, -1 do
			local creature = creatures[i]
			if creature ~= self then
				local distX = creature.pos.x - self.pos.x
				local distY = creature.pos.y - self.pos.y
				local dist_sq = distX*distX + distY*distY
				if dist_sq <= self.aggro_range ^ 2 then
					self.target = creature
					return "Pursuing"
				end
			end
		end
	end,
}

drone_states.Pursuing = {
	-- timer is for exclamation mark graphic
	timer = 0,
	mod_timer = 0,
	enter = function(self)
		timer = 0
		mod_timer = 0
		self.size = 5
	end,

	update = function(self, dt)
		-- move towards target steadily
		local distX = self.target.pos.x - self.pos.x
		local distY = self.target.pos.y - self.pos.y
		self.vel = vector_normalize({x = distX, y = distY})
		self.vel.x = self.vel.x * 25
		self.vel.y = self.vel.y * 25
		if timer then
			timer = timer + dt
			mod_timer = mod_timer + dt * 5
			if timer > 2 then
				timer = nil
			end
		end
		

		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		local dist_sq = distX*distX + distY*distY
		if dist_sq >= self.forget_range ^ 2 then
			if math.random() > 0.5 then
				return "Wandering"
			else
				return "Waiting"
			end
		end
	end,

	draw = function(self)
		if timer then
			love.graphics.setColor(0, 0, 0)
			draw_bouncy_exclamation_mark(self.pos.x+1, self.pos.y+1, mod_timer)
			love.graphics.setColor(1, 0.1, 0.3)
			draw_bouncy_exclamation_mark(self.pos.x, self.pos.y, mod_timer)
			love.graphics.setColor(1, 1, 1)
		end
	end
}



drone_states.Hungry = {

}

drone_states.Attacking = {
	-- figure out how to bounce
}

function create_drone(posX, posY)
	local drone = {
		state_machine = sm.new(),
		pos = {x = posX, y = posY},
		vel = {x = 0, y = 0},
		hunger = 0,
		size = 5,
		aggro_range = 50,
		forget_range = 50, 
	}

	drone.state_machine.entity = drone
	drone.state_machine:add_state("Wandering", drone_states.Wandering)
	drone.state_machine:add_state("Waiting", drone_states.Waiting)
	drone.state_machine:add_state("Hungry", drone_states.Hungry)
	drone.state_machine:add_state("Attacking", drone_states.Attacking)
	drone.state_machine:add_state("Pursuing", drone_states.Pursuing)
	drone.state_machine:transition_to("Waiting")

	function drone:update(dt)
		self.state_machine:update(dt)
		self.hunger = self.hunger + dt
	end

	function drone:draw()
		
		love.graphics.circle('fill', self.pos.x, self.pos.y, self.size)
		self.state_machine:draw()
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(math.floor(self.hunger), math.floor(self.pos.x), math.floor(self.pos.y))
	end

	return drone
end