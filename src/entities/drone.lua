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
			end
		end

		-- lerp towards move_node
		local desired = compute_desired_velocity(self, self.move_node, 25)
		local damping = 1
		local t = math.min(damping * dt, 1)
		self.vel = lerp_vector(self.vel, desired, t)

		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		-- search for other creature logic
		local nearby_entities = SpatialManager:query(self.pos, self.aggro_range)
		for i = #nearby_entities, 1, -1 do
			local entity = nearby_entities[i]
			if entity ~= self and entity.entity_type == "creature" then
				local distX = entity.pos.x - self.pos.x
				local distY = entity.pos.y - self.pos.y
				local dist_sq = distX*distX + distY*distY
				if dist_sq <= self.aggro_range ^ 2 then
					self.target = entity
					return "Pursuing"
				end
			end
		end
	end,

	draw = function(self)
		love.graphics.circle('fill', self.move_node.x, self.move_node.y, 1)
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
		local nearby_entities = SpatialManager:query(self.pos, self.aggro_range)
		for i = #nearby_entities, 1, -1 do
			local entity = nearby_entities[i]
			if entity ~= self and entity.entity_type == "creature" then
				local distX = entity.pos.x - self.pos.x
				local distY = entity.pos.y - self.pos.y
				local dist_sq = distX*distX + distY*distY
				if dist_sq <= self.aggro_range ^ 2 then
					self.target = entity
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
		self.collision_cooldown = 0
		timer = 0
		mod_timer = 0
		self.size = 5
	end,

	update = function(self, dt)
		if timer then
			timer = timer + dt
			mod_timer = mod_timer + dt * 5
			if timer > 2 then
				timer = nil
			end
		end

		-- move towards target steadily
		local desired = compute_desired_velocity(self, self.target.pos, 25)
		local damping = 5
		local t = math.min(damping * dt, 1)
		self.vel = lerp_vector(self.vel, desired, t)
		
		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		local dist_x = self.target.pos.x - self.pos.x
		local dist_y = self.target.pos.y - self.pos.y
		local dist_sq = dist_x*dist_x + dist_y*dist_y
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



-- creation function
function create_drone(posX, posY)
	local drone = {
		state_machine = StateMachine.new(),
		pos = {x = posX, y = posY},
		vel = {x = 0, y = 0},
		entity_type = EntityType.creature,
		collision_cooldown = 0,
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
		self.hitbox = {x = self.pos.x - 3, y = self.pos.y - 3, w = 6, h = 6}
		self.collision_cooldown = math.max(0, self.collision_cooldown - dt)

		local nearby_entities = SpatialManager:query(self.pos, self.aggro_range)
		for _, entity in ipairs(nearby_entities) do
			if AABB_collision(self, entity) and self.collision_cooldown == 0 and self ~= entity then
				local normal = get_collision_normal(self, entity)
				local new_vel = reflect_velocity(self.vel, normal)
				self.vel.x = new_vel.x * 10
				self.vel.y = new_vel.y * 10
				self.collision_cooldown = 0.5
			end
		end
	end

	function drone:draw()
		love.graphics.setColor(1, 1, 1)
		love.graphics.circle('fill', self.pos.x, self.pos.y, self.size)
		self.state_machine:draw()
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(math.floor(self.hunger), math.floor(self.pos.x), math.floor(self.pos.y))
		love.graphics.setColor(0, 1, 0)
		love.graphics.rectangle('line', self.hitbox.x, self.hitbox.y, self.hitbox.w, self.hitbox.h)
		love.graphics.setColor(1, 1, 1)
	end

	SpatialManager:register_entity(drone)
	return drone
end