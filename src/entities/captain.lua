local anim8 = require('lib/anim8')
local sfxr = require('lib/sfxr')

local captain_sheet = love.graphics.newImage('assets/sprites/captain/captain_sheet.png')
captain_sheet:setFilter("nearest", "nearest")
local captain_ship_grid = anim8.newGrid(22, 22, captain_sheet:getWidth(), captain_sheet:getHeight())
local captain_ship_animation = anim8.newAnimation(captain_ship_grid('1-5', 1), 0.05)
local jet_plume_grid = anim8.newGrid(5, 12, captain_sheet:getWidth(), captain_sheet:getHeight(), 0, 23)
local jet_plume_animation = anim8.newAnimation(jet_plume_grid('1-2', 1), 0.05)

function create_pellet(posX, posY, direction_vector)
	local pellet = {
		pos = {x = posX, y = posY},
		vel = direction_vector,
		speed = speed,
	}
	function pellet:update(dt)
		self.pos.x = self.pos.x + self.vel.x * dt
		self.pos.y = self.pos.y + self.vel.y * dt
	end
	function pellet:draw()
		love.graphics.circle('fill', self.pos.x, self.pos.y, 2.5)
	end
	return pellet
end

function face_towards_coordinate(ex, ey, x, y)
	-- ex, ey are coordinates of entity (these should probably be the entity's center)
	local original_angle = math.atan2(y - ey, x - ex)
	original_angle = original_angle % (2 * math.pi) -- normalize angle to [0, 2pi)
	local snap_step = math.rad(11.25)
	local snapped_angle = math.floor(original_angle / snap_step + 0.5) * snap_step -- compute snap step to nearest angle of snap step
	snapped_angle = snapped_angle % (2 * math.pi) -- normalize new angle to [0, 2pi)
	return snapped_angle
end

local captain_states = {}

captain_states.Idle = {
	enter = function(self)
		self.vel = {x = 0, y = 0}
	end,

	update = function(self, dt)
		if love.keyboard.isDown('a') then 
			self.vel.x = -1 
		end
		if love.keyboard.isDown('d') then 
			self.vel.x = 1 
		end
		if love.keyboard.isDown('w') then 
			self.vel.y = -1 
		end
		if love.keyboard.isDown('s') then 
			self.vel.y = 1 
		end

		if self.vel.x ~= 0 or self.vel.y ~= 0 then
			return "Moving"
		end

		captain_ship_animation:update(dt)
		
	end,

	draw = function(self)

	end,
}

captain_states.Moving = {
	update = function(self, dt)
		self.vel = {x = 0, y = 0}
		if love.keyboard.isDown('a') then 
			self.vel.x = -1 
		end
		if love.keyboard.isDown('d') then 
			self.vel.x = 1 
		end
		if love.keyboard.isDown('w') then 
			self.vel.y = -1 
		end
		if love.keyboard.isDown('s') then 
			self.vel.y = 1 
		end

		-- normalize movement vector
		local vel_len = math.sqrt(self.vel.x^2 + self.vel.y^2)
		if vel_len > 0 then
			self.vel.x = self.vel.x / vel_len
			self.vel.y = self.vel.y / vel_len
		end

		-- update player position based on velocity table
		self.pos.x = self.pos.x + self.vel.x * self.max_speed * dt
		self.pos.y = self.pos.y + self.vel.y * self.max_speed * dt

		if self.vel.x == 0 and self.vel.y == 0 then
			return "Idle"
		end

		captain_ship_animation:update(dt)
		jet_plume_animation:update(dt)
	end,

	draw = function(self)
		love.graphics.push()
		love.graphics.translate(math.floor(self.pos.x), math.floor(self.pos.y))
		love.graphics.rotate(self.facing + (90 * (math.pi / 180)))
		jet_plume_animation:draw(captain_sheet, 0, 0, 0, 1.2, 1.5, 2.5, -2)
		love.graphics.pop()
	end,
}


function create_captain_player(posX, posY)
	-- this is demo test player character
	local captain = {
		state_machine = sm.new(),
		pos = {x = posX, y = posY},
		vel = {x = 0, y = 0},
		max_speed = 100,
		facing = 0,
		name = "jack",

		shoot_cooldown = 0,	
		shoot_attack_speed = 1, -- this value should be used for every attack type, just divide it or multiply it when you need a faster or slower attack speed
		bullet_velocity = 500,

		moving = false,
	}

	-- state machine instantiation
	captain.state_machine.entity = captain
	captain.state_machine:add_state("Moving", captain_states.Moving)
	captain.state_machine:add_state("Idle", captain_states.Idle)
	captain.state_machine:transition_to("Idle")


	function captain:shoot(direction_vector)
		if self.shoot_cooldown > 0 then return end -- if shoot on cooldown, do not continue

		local pellet = create_pellet(self.pos.x, self.pos.y, direction_vector)
		
		-- set relative cooldown based on shoot_cooldown
		self.shoot_cooldown = self.shoot_attack_speed / 6
		table.insert(bullets, pellet)
	end


	function captain:update(dt)
		self.state_machine:update(dt)

		
		-- face towards mouse

		-- these coordinates are probably a band-aid for this problem
		-- but this is necessary due to the camera logic
		local mouse_cam_x = mouse_x + camera_x - (game_width / 2)
		local mouse_cam_y = mouse_y + camera_y - (game_height / 2)

		self.facing = face_towards_coordinate(self.pos.x, self.pos.y, mouse_cam_x, mouse_cam_y)

		-- combat cooldowns
		self.shoot_cooldown = math.max(0, self.shoot_cooldown - dt)

		-- shoot mechanic, change this below to allow for dynamically switched shot types
		if love.mouse.isDown(1) then
			self:shoot(vector_scalar_multiply(vector_normalize({x = mouse_cam_x - self.pos.x, y = mouse_cam_y - self.pos.y}), self.bullet_velocity))
		end


		-- collectible collector
		for i = #collectibles, 1, -1 do
			local collectible = collectibles[i]
			local distX = collectible.pos.x - self.pos.x
			local distY = collectible.pos.y - self.pos.y
			local dist_sq = distX*distX + distY*distY
			if dist_sq <= 150 then
				collectible.DESTROY_THIS = true
			end
		end
	end


	function captain:draw()
		love.graphics.push()
		self.state_machine:draw()

		-- draw with integer position and rotation
		love.graphics.translate(math.floor(self.pos.x), math.floor(self.pos.y))
		love.graphics.rotate(self.facing + (90 * (math.pi / 180)))

		captain_ship_animation:draw(captain_sheet, 0, 0, 0, 1, 1, 11, 11)
		--love.graphics.circle('line', 0, 0, math.sqrt(150))
		love.graphics.pop()


	end
	return captain
end