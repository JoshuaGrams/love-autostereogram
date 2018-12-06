local Stereogram = require 'autostereogram'

local function changeEyeSeparationBy(n, m)
	m = m or n
	stereogram:setSeparation(stereogram.separation + n, stereogram.minSeparation + m)
end

function love.load()
	love.mouse.setVisible(false)
	local pattern = love.graphics.newImage('fall-color-tile.png')
	local w, h = love.graphics.getDimensions()
	stereogram = Stereogram:new(pattern, w, h)
	stereogram:setSeparation(270, 220)
	circle = { x = 800, y = 500, r = 120, dx = 0, dy = 0 }
	sphere = love.graphics.newImage('ball.png')

	roboto = love.graphics.newFont('Roboto-Bold.ttf', 384)
	t = 0
end

local function scancode(...)
	return love.keyboard.isScancodeDown(...) and 1 or 0
end

local function scancodeAxis(pos, neg)
	return scancode(pos) - scancode(neg)
end

local function scancodeStick(xPos, xNeg, yPos, yNeg)
	local x = scancodeAxis(xPos, xNeg)
	local y = scancodeAxis(yPos, yNeg)
	local d2 = x * x + y * y
	if d2 > 1 then
		local scale = 1 / math.sqrt(d2)
		x, y = x * scale, y * scale
	end
	return x, y
end

function love.update(dt)
	t = t + dt
	local dx, dy = scancodeStick('right', 'left', 'down', 'up')
	local accel = 500
	circle.dx = circle.dx + dt * dx * accel
	circle.dy = circle.dy + dt * dy * accel
	circle.x = circle.x + dt * circle.dx
	circle.y = circle.y + dt * circle.dy
	local w, h = stereogram.heightMap:getDimensions()
	if circle.x + circle.r > w - 1 then
		circle.x = w - 1 - circle.r
		circle.dx = -circle.dx
	elseif circle.x < circle.r then
		circle.x = circle.r
		circle.dx = -circle.dx
	end
	if circle.y + circle.r > h - 1 then
		circle.y = h - 1 - circle.r
		circle.dy = -circle.dy
	elseif circle.y < circle.r then
		circle.y = circle.r
		circle.dy = -circle.dy
	end
end

local function drawGrayscaleGame()
	local gray

	gray = 0.125
	love.graphics.setFont(roboto)
	love.graphics.setColor(gray, gray, gray)
	love.graphics.print("This is a...", 50, 250)

	gray = 0.5
	love.graphics.setColor(gray, gray, gray)
	local iw, ih = sphere:getDimensions()
	local scale = 2 * circle.r / iw
	love.graphics.draw(sphere, circle.x, circle.y, 0, scale, scale, iw/2, ih/2)
end

function love.draw()
	local wWindow, hWindow = love.graphics.getDimensions()
	stereogram:resize(wWindow, hWindow, 0, 0)
	stereogram:setHeightMap()
	love.graphics.clear(0, 0, 0)
	drawGrayscaleGame()
	love.graphics.setCanvas()

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(stereogram:render(), 0, 0)
end

function toggleFullscreen()
	local wasFull = love.window.getFullscreen()
	love.window.setFullscreen(not wasFull, 'desktop')
end

function love.keypressed(k, s)
	local alt = love.keyboard.isDown('lalt', 'ralt')
	if k == 'escape' then
		love.event.quit()
	elseif k == 'f11' or (alt and k == 'return') then
		toggleFullscreen()
	elseif k == '1' then
		changeEyeSeparationBy(1)
	elseif k == '2' then
		changeEyeSeparationBy(-1)
	elseif k == 'pageup' then
		changeEyeSeparationBy(10)
	elseif k == 'pagedown' then
		changeEyeSeparationBy(-10)
	elseif k == '3' then
		changeEyeSeparationBy(0, 1)
	elseif k == '4' then
		changeEyeSeparationBy(0, -1)
	end
end
