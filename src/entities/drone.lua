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

local drone_states = {}

drone_states.Wandering = {
	enter = function(self)
		self.move_node_timer = 0
		-- create a node between 100 and 20 units away from the x, y
		local dist = 20 + math.random() * 40
		self.move_node = get_random_coordinate_away(self.pos.x, self.pos.y, dist)
		-- set velocity towards move_node
		self.vel = vector_normalize({x = self.move_node.x - self.pos.x, y = self.move_node.y - self.pos.y})
		self.vel = {x = self.vel.x * 25, y = self.vel.y * 25}

	end,

	update = function(self, dt)
		self.move_node_timer = self.move_node_timer + dt
		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt

		-- stop if reach node
		local epsilon = 1
		if math.abs(self.pos.x - self.move_node.x) <= epsilon and math.abs(self.pos.y - self.move_node.y) <= epsilon then
			self.vel = {x = 0, y = 0}
		end

		if self.move_node_timer > 5 then
			
		end
		-- if self.move_node_timer > 1 then
		-- 	local dist = 20 + math.random() * 160
		-- 	local degrees = vector_to_degrees(self.vel)
		-- 	local min_degrees = degrees - 50
		-- 	local max_degrees = degrees + 50
		-- 	self.move_node = get_random_coordinate_away_range(self.pos.x, self.pos.y, dist, min_degrees, max_degrees)
		-- 	-- set velocity towards move_node
		-- 	self.vel = vector_normalize({x = self.move_node.x - self.pos.x, y = self.move_node.y - self.pos.y})
		-- 	self.vel = {x = self.vel.x * 25, y = self.vel.y * 25}
		-- 	self.move_node_timer = 0
	end,

	draw = function(self)
		love.graphics.circle('fill', self.move_node.x, self.move_node.y, 1)
		love.graphics.line(self.pos.x, self.pos.y, self.pos.x + self.vel.x, self.pos.y + self.vel.y)
	end
}

drone_states.Hungry = {

}

drone_states.Attacking = {

}

function create_drone(posX, posY)
	local drone = {
		state_machine = sm.new(),
		pos = {x = posX, y = posY},
		vel = {x = 0, y = 0},
		hunger = 0,
	}

	drone.state_machine.entity = drone
	drone.state_machine:add_state("Wandering", drone_states.Wandering)
	drone.state_machine:transition_to("Wandering")

	function drone:update(dt)
		self.state_machine:update(dt)
	end

	function drone:draw()
		self.state_machine:draw()
		love.graphics.circle('fill', self.pos.x, self.pos.y, 5)
	end

	return drone
end