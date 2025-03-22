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

function entity_utilities:create_triangle_player(x, y)
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
	}
	function player:shoot(direction_vector)
		if self.shoot_cooldown > 0 then return end

		local pellet = entity_utilities:create_pellet(self.pos.x, self.pos.y, direction_vector)
		
		-- set relative cooldown based on shoot_cooldown
		self.shoot_cooldown = self.shoot_attack_speed / 6
		table.insert(entity_utilities.bullets, pellet)
	end
	function player:update(dt)
		-- use this in love:update, probably add this to some overarching table like dudes {}
		player.vel = {x = 0, y = 0}
		if love.keyboard.isDown('a') then player.vel.x = -1 end
		if love.keyboard.isDown('d') then player.vel.x = 1 end
		if love.keyboard.isDown('w') then player.vel.y = -1 end
		if love.keyboard.isDown('s') then player.vel.y = 1 end

		-- normalize movement here
		local vel_len = math.sqrt(player.vel.x^2 + player.vel.y^2)
		
		if vel_len > 0 then
			player.vel.x = player.vel.x / vel_len
			player.vel.y = player.vel.y / vel_len
		end

		-- update player position based on velocity table
		player.pos.x = player.pos.x + player.vel.x * player.max_speed * dt
		player.pos.y = player.pos.y + player.vel.y * player.max_speed * dt
		player.facing = math.atan2(m_y - player.pos.y, m_x - player.pos.x)

		-- combat cooldowns
		player.shoot_cooldown = math.max(0, player.shoot_cooldown - dt)

		
		-- shoot mechanic
		if love.mouse.isDown(1) then
			player:shoot(vector_scalar_multiply(vector_normalize({x = m_x - player.pos.x, y = m_y - player.pos.y}), player.bullet_velocity))
		end
	end
	function player:draw()

		local size = 7.5
		love.graphics.push()
		love.graphics.translate(player.pos.x, player.pos.y)
		love.graphics.rotate(player.facing)

		-- i dont know wtf this is but it makes a triangle polygon goated
		love.graphics.polygon('fill', {
			size, 0,
			-size/2, size/2,
			-size/2, -size/2
		})
		love.graphics.pop()
	end
	return player
end

return entity_utilities