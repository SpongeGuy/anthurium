game_width, game_height = 480, 270
window_width, window_height = love.window.getDesktopDimensions()
window_game_ratio = window_width / game_width

local gamera = require("lib/gamera")

local l, t, w, h = -2000, -2000, 4000, 4000
camera = gamera.new(l, t, w, h)
camera:setWindow(0, 0, 480, 270)




print(window_game_ratio)