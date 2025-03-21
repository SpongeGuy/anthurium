local push = require("push")
local game_width, game_height = 480, 270
local window_width, window_height = love.window.getDesktopDimensions()

love.graphics.setDefaultFilter("nearest", "nearest")
push:setupScreen(game_width, game_height, window_width, window_height, {fullscreen = true, pixelperfect = true, highdpi = true})

local entities = {}
local bullets = {}

function create_bullet(posX, posY, dx, dy, speed)
	
	return bullet
end


function create_triangle_player(x, y)
	local posX = x or 0
	local posY = y or 0
	local player = {
		pos = {x = posX, y = posY},
		vel = {x = 0, y = 0},
		max_speed = 100,
		accel = 750,
		decel = 2500,
		facing = 0,
		attack_speed = 0.1

	}
	function player:shoot()
		local bullet = {
			pos = {x = player.pos.x, y = player.pos.y},
			vel = {x = dx, y = dy},
			speed = speed,
		}
		function bullet:update(dt)
			bullet.pos.x = bullet.pos.x + bullet.vel.x * dt
			bullet.pos.y = bullet.pos.y + bullet.vel.y * dt
		end
		function bullet:draw()
			love.graphics.circle('fill', bullet.pos.x, bullet.pos.y, 5)
		end
	end
	function player:update(dt)
		player.vel = {x = 0, y = 0}
		if love.keyboard.isDown('a') then player.vel.x = -1 end
		if love.keyboard.isDown('d') then player.vel.x = 1 end
		if love.keyboard.isDown('w') then player.vel.y = -1 end
		if love.keyboard.isDown('s') then player.vel.y = 1 end

		local vel_len = math.sqrt(player.vel.x^2 + player.vel.y^2)
		print(vel_len)
		if vel_len > 0 then
			player.vel.x = player.vel.x / vel_len
			player.vel.y = player.vel.y / vel_len
		end

		player.pos.x = player.pos.x + player.vel.x * player.max_speed * dt
		player.pos.y = player.pos.y + player.vel.y * player.max_speed * dt

		player.facing = math.atan2(m_y - player.pos.y, m_x - player.pos.x)
	end
	function player:draw()
		local size = 7.5
		love.graphics.push()
		love.graphics.translate(player.pos.x, player.pos.y)
		love.graphics.rotate(player.facing)
		love.graphics.polygon('fill', {
			size, 0,
			-size/2, size/2,
			-size/2, -size/2
		})
		love.graphics.pop()
	end
	return player
end

function approach(current, target, max_change)
	if current < target then
		return math.min(current + max_change, target)
	else
		return math.max(current - max_change, target)
	end
end



function love.load()
	player = create_triangle_player(100, 100)
end



function love.update(dt)
	m_x, m_y = love.mouse.getPosition()
	m_x = m_x / 4
	m_y = m_y / 4
	player:update(dt)
	for i = #bullets, 1, -1 do
		bullets[i]:update(dt)
	end
end



function love.draw()
	push:start()
		player:draw()
	push:finish()
	for i = #bullets, 1, -1 do
		bullets[i]:draw()
	end
	love.graphics.print(player.vel.x, 0, 0)
	love.graphics.print(player.vel.y, 0, 20)
end