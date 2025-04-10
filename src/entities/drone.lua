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

function draw_bouncy_text(text, x, y, timer)
	local A = 25
	local l = 0.5
	local e = 2.71828
	local h = 0.9
	local B = 1.5
	-- bouncy exclamation mark equation
	love.graphics.print(text, math.floor(x), math.floor(y - (A*e^(-l*(timer^h)) * math.abs(math.sin(B*timer)))))
end

local drone_states = {}

drone_states.Wandering = {
	enter = function(self)
		-- create a node between 100 and 20 units away from the x, y
		local dist = 20 + random_float(0, 40)
		self.move_node = get_random_coordinate_away(self.pos.x, self.pos.y, dist)
		self.move_branches = math.random(0, 4)
		self.state = "Wn"
		self.target = nil
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
				local dist = 20 + random_float(0, 160)
				local degrees = vector_to_degrees(self.vel)
				local min_degrees = degrees - 50
				local max_degrees = degrees + 50
				self.move_node = get_random_coordinate_away_range(self.pos.x, self.pos.y, dist, min_degrees, max_degrees)
			end
		end

		-- lerp towards move_node
		local desired = compute_desired_velocity(self, self.move_node, self.move_speed)
		local damping = 2
		local t = math.min(damping * dt, 1)
		self.vel = lerp_vector(self.vel, desired, t)

		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		-- search for other creature logic
		local nearby_entities
		if self.hunger > 25 then
			nearby_entities = SpatialManager:query(self.pos, self.aggro_range * 6) -- self.aggro_range should be subbed w a parameter
			for i = #nearby_entities, 1, -1 do
				local entity = nearby_entities[i]
				if entity ~= self and entity.entity_type == "fruit" and entity.being_eaten == false then -- conditions here should be a parameter
					-- the function being executed here should be a parameter
					local distX = entity.pos.x - self.pos.x
					local distY = entity.pos.y - self.pos.y
					local dist_sq = distX*distX + distY*distY
					if dist_sq <= (self.aggro_range * 6) ^ 2 then
						self.target = entity
						return "Hungry"
					end
				end
			end
		end
		if self.pursue_cooldown == 0 then
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
		end
	end,
}



drone_states.Waiting = {
	enter = function(self)
		
		self.timer = 0
		self.random_wait_value = math.random(2, 5)
		self.size = 5
		self.state = "Wt"
		self.target = nil
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
		if self.pursue_cooldown == 0 then
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
		self.state = "P"
	end,

	update = function(self, dt)
		if timer then
			timer = timer + dt
			mod_timer = mod_timer + dt * 5
			if timer > 2 then
				timer = nil
			end
		end

		-- prevent drone from freezing if target dies
		-- i should probably figure out a way to reorganize the code so this isn't needed
		if self.target._destroy_this then
			self.target = nil
			return "Waiting"
		end

		-- move towards target steadily
		local desired = compute_desired_velocity(self, self.target.pos, self.move_speed)
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
}



drone_states.Hungry = {
	enter = function(self)
		self.size = 5
		self.eating_timer = 3
		self.eating_patience = 20
		self.state = "H"
	end,

	update = function(self, dt)
		local desired = compute_desired_velocity(self, self.target.pos, self.move_speed)
		local damping = 3
		local t = math.min(damping * dt, 1)
		self.vel = lerp_vector(self.vel, desired, t)

		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		-- if the drone cannot reach the fruit in time, it will (probably) choose a closer target
		self.eating_patience = math.max(0, self.eating_patience - dt)
		if self.eating_patience == 0 then
			return "Wandering"
		end

		if AABB_collision(self, self.target) then
			self.target.being_eaten = true
			self.eating = true
		elseif self.eating == true then
			-- toggle these booleans to allow competition
			-- this will probably get shared between entities ?
			self.target.being_eaten = false
			self.eating = false
		end

		if self.target.being_eaten and not self.eating then
			return "Wandering"
		end

		if self.eating then
			self.eating_timer = math.max(0, self.eating_timer - dt)
		else
			self.eating_timer = 3
		end

		-- eat fruit
		if self.eating_timer == 0 then
			self.hunger = self.hunger - self.target.nutrition
			self.health = self.health + 3
			self.target._destroy_this = true
			self.target = nil
			if self.hunger < 0 then
				return "Wandering"
			end
			local nearby_entities = SpatialManager:query(self.pos, self.aggro_range)
			for i = #nearby_entities, 1, -1 do
				local entity = nearby_entities[i]
				if entity ~= self and entity.entity_type == "fruit" and entity.being_eaten == false then
					local distX = entity.pos.x - self.pos.x
					local distY = entity.pos.y - self.pos.y
					local dist_sq = distX*distX + distY*distY
					if dist_sq <= (self.aggro_range * 3) ^ 2 then
						self.target = entity
						return "Hungry"
					end
				end
			end
			return "Wandering"
		end

	end
}

-- creation function
function create_drone(posX, posY)
	local drone = create_new_entity(posX, posY, EntityType.creature)
	drone.move_speed = 35
	drone.collision_cooldown = 0
	drone.hunger = 0
	drone.size = 5
	drone.aggro_range = 50
	drone.forget_range = 50
	drone.pursue_cooldown = 0
	drone.health = 20
	drone.color = {random_float(0.8, 1), random_float(0.6, 1), random_float(0.8, 1)}

	drone.state = "h"

	drone.state_machine:add_state("Wandering", drone_states.Wandering)
	drone.state_machine:add_state("Waiting", drone_states.Waiting)
	drone.state_machine:add_state("Hungry", drone_states.Hungry)
	drone.state_machine:add_state("Pursuing", drone_states.Pursuing)
	drone.state_machine:transition_to("Waiting")

	function drone:update(dt)
		self.state_machine:update(dt)
		self.hunger = self.hunger + dt
		self.hitbox = {x = self.pos.x - 3, y = self.pos.y - 3, w = 6, h = 6}
		self.collision_cooldown = math.max(0, self.collision_cooldown - dt)
		self.pursue_cooldown = math.max(0, self.pursue_cooldown - dt)

		local nearby_entities = SpatialManager:query(self.pos, self.aggro_range)
		for _, entity in ipairs(nearby_entities) do
			if AABB_collision(self, entity) and self.collision_cooldown == 0 and self ~= entity and entity.entity_type ~= "fruit" then
				self.health = self.health - 1
				if self.health <= 0 then
					self._destroy_this = true
					break
				end

				-- this logic is so fucked up and it's probably not gonna improve any time soon lel
				local current_vel_length = math.sqrt(self.vel.x^2 + self.vel.y^2)
				local normal = get_collision_normal(self, entity)
				local new_vel = reflect_velocity(self.vel, normal)
				local bounce_speed = 250
				local entity_velocity_normalized = vector_normalize(entity.vel)

				if current_vel_length < self.move_speed - 10 then
					-- if going slow or stationary, use this logic
					self.vel.x = (normal.x + math.random()) * bounce_speed
					self.vel.y = (normal.y + math.random()) * bounce_speed
				else
					self.vel.x = (new_vel.x + math.random()) * bounce_speed / 50
					self.vel.y = (new_vel.y + math.random()) * bounce_speed / 50
				end
				self.collision_cooldown = 0.4

				-- on collision, randomly decide to wander
				if math.random() < 0.1 then
					self.pursue_cooldown = math.random(4, 8)
					self.state_machine:transition_to("Wandering")
				end
			end
		end
	end



	function drone:draw()
		love.graphics.setColor(unpack(self.color))
		love.graphics.circle('fill', self.pos.x, self.pos.y, self.size)
		self.state_machine:draw()
		love.graphics.setColor(0, 0, 0)
		-- love.graphics.print(self.state, math.floor(self.pos.x), math.floor(self.pos.y))
		-- if self.target then
		-- 	love.graphics.print("h", math.floor(self.pos.x), math.floor(self.pos.y + 8))
		-- end
		love.graphics.setColor(1, 1, 1)
	end
	
	return drone
end