local entity_spawners = {}

entity_spawners:create_triangle_player(x, y)
	-- this is demo test player character
	local posX = x or 0
	local posY = y or 0
	local player = {
		pos = {x = posX, y = posY},
		vel = {x = 0, y = 0},
		max_speed = 100,
		facing = 0,

		shoot_cooldown = 0,
		shoot_attack_speed = 1,
		bullet_velocity = 250,
	}
	function player:shoot(direction_vector)
		if self.shoot_cooldown > 0 then return end

		
		local bullet = {
			pos = {x = player.pos.x, y = player.pos.y},
			vel = direction_vector,
			speed = speed,
		}
		function bullet:update(dt)
			bullet.pos.x = bullet.pos.x + bullet.vel.x * dt
			bullet.pos.y = bullet.pos.y + bullet.vel.y * dt
		end
		function bullet:draw()
			love.graphics.circle('fill', bullet.pos.x, bullet.pos.y, 2.5)
		end

		self.shoot_cooldown = self.shoot_attack_speed / 5
		table.insert(bullets, bullet)
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