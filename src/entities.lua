local anim8 = require('lib/anim8')
local sfxr = require('lib/sfxr')

local captain_sheet = love.graphics.newImage('assets/sprites/captain/captain_sheet.png')
local captain_ship_grid = anim8.newGrid(22, 22, captain_sheet:getWidth(), captain_sheet:getHeight())
local captain_ship_animation = anim8.newAnimation(captain_ship_grid('1-5', 1), 0.05)
local jet_plume_grid = anim8.newGrid(5, 12, captain_sheet:getWidth(), captain_sheet:getHeight(), 0, 23)
local jet_plume_animation = anim8.newAnimation(jet_plume_grid('1-2', 1), 0.05)

captain_sheet:setFilter("nearest", "nearest")


local entity_utilities = {
	entities = {},
	bullets = {},
}



-- entity spawn functions should always return the object, never add it to a table directly within function

function entity_utilities:create_pellet(posX, posY, direction_vector)
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

function entity_utilities:create_captain_player(x, y)
	-- this is demo test player character
	local posX = x or 0
	local posY = y or 0
	local player = {
		pos = {x = posX, y = posY},
		vel = {x = 0, y = 0},
		max_speed = 100,
		facing = 0,

		shoot_cooldown = 0,	
		shoot_attack_speed = 1, -- this value should be used for every attack type, just divide it or multiply it when you need a faster or slower attack speed
		bullet_velocity = 500,

		moving = false,
	}
	function player:shoot(direction_vector)
		if self.shoot_cooldown > 0 then return end -- if shoot on cooldown, do not continue

		local pellet = entity_utilities:create_pellet(self.pos.x, self.pos.y, direction_vector)
		
		-- set relative cooldown based on shoot_cooldown
		self.shoot_cooldown = self.shoot_attack_speed / 6
		table.insert(entity_utilities.bullets, pellet)
	end
	function player:update(dt)
		-- use this in love:update, probably add this to some overarching table like dudes {}
		self.vel = {x = 0, y = 0}
		self.moving = false
		if love.keyboard.isDown('a') then 
			self.vel.x = -1 
			self.moving = true
		end
		if love.keyboard.isDown('d') then 
			self.vel.x = 1 
			self.moving = true
		end
		if love.keyboard.isDown('w') then 
			self.vel.y = -1 
			self.moving = true
		end
		if love.keyboard.isDown('s') then 
			self.vel.y = 1 
			self.moving = true
		end

		-- normalize movement here
		local vel_len = math.sqrt(self.vel.x^2 + self.vel.y^2)
		
		if vel_len > 0 then
			self.vel.x = self.vel.x / vel_len
			self.vel.y = self.vel.y / vel_len
		end

		-- update player position based on velocity table
		self.pos.x = self.pos.x + self.vel.x * self.max_speed * dt
		self.pos.y = self.pos.y + self.vel.y * self.max_speed * dt

		-- facing angle calculation
		local original_angle = math.atan2(m_y - self.pos.y, m_x - self.pos.x)
		
		original_angle = original_angle % (2 * math.pi) -- normalize angle to [0, 2pi)
		local snap_step = math.rad(11.25)
		local snapped_angle = math.floor(original_angle / snap_step + 0.5) * snap_step -- compute snap step to nearest angle of snap step
		snapped_angle = snapped_angle % (2 * math.pi) -- normalize new angle to [0, 2pi)
		self.facing = snapped_angle

		-- combat cooldowns
		self.shoot_cooldown = math.max(0, self.shoot_cooldown - dt)

		-- shoot mechanic, change this below to allow for dynamically switched shot types
		if love.mouse.isDown(1) then
			self:shoot(vector_scalar_multiply(vector_normalize({x = m_x - self.pos.x, y = m_y - self.pos.y}), self.bullet_velocity))
		end
		captain_ship_animation:update(dt)
		jet_plume_animation:update(dt)
	end
	function player:draw()

		local size = 7.5
		love.graphics.push()

		-- draw with integer position and rotation
		love.graphics.translate(math.floor(self.pos.x), math.floor(self.pos.y))
		love.graphics.rotate(self.facing + (90 * (math.pi / 180)))
		if self.moving then
			jet_plume_animation:draw(captain_sheet, 0, 0, 0, 1.2, 1.5, 2.5, -2)
		end
		captain_ship_animation:draw(captain_sheet, 0, 0, 0, 1, 1, 11, 11)
		
		love.graphics.pop()
	end
	return player
end

return entity_utilities