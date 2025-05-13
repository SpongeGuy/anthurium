-- ideally keep main.lua free from any other function definitions other than
-- love.load, love.update, and love.draw

push = require("lib/push")
require("src/Camera")
require("src/entities/entities")
require("src/game")

function love.load()
	game = create_game()
end

function love.update(dt)
	game:update(dt)
end

function love.draw()
	game:draw()
end