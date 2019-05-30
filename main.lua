local Stereogram = require 'autostereogram'

local function changeEyeSeparationBy(n, m)
	m = m or n
	stereogram:setSeparation(stereogram.separation + n, stereogram.minSeparation + m)
end

local function scrollPattern(pattern, dx, dy, out, quads)
	local w, h = pattern:getDimensions()
	local ox, oy = math.floor(dx % w), math.floor(dy % h)
	if out then
		quads[1]:setViewport(0, 0,  w-ox, h-oy)
		quads[2]:setViewport(w-ox, 0,  ox, h-oy)
		quads[3]:setViewport(0, h-oy,  w-ox, oy)
		quads[4]:setViewport(w-ox, h-oy,  ox, oy)
	else
		out = love.graphics.newCanvas(w, h)
		quads = {
			love.graphics.newQuad(0, 0,  w-ox, h-oy,  w, h),
			love.graphics.newQuad(w-ox, 0,  ox, h-oy,  w, h),
			love.graphics.newQuad(0, h-oy,  w-ox, oy,  w, h),
			love.graphics.newQuad(w-ox, h-oy,  ox, oy,  w, h)
		}
	end

	local oldCanvas = love.graphics.getCanvas()
	love.graphics.setCanvas(out)
	love.graphics.origin()
	love.graphics.setColor(1, 1, 1)
	love.graphics.clear(0, 0, 0)
	love.graphics.draw(pattern, quads[1], ox, oy)
	love.graphics.draw(pattern, quads[2], 0, oy)
	love.graphics.draw(pattern, quads[3], ox, 0)
	love.graphics.draw(pattern, quads[4], 0, 0)
	love.graphics.setCanvas(oldCanvas)
	return out, quads
end

function love.load()
	love.mouse.setVisible(false)
	basePattern = love.graphics.newImage('fall-color-tile.png')
	local w, h = love.graphics.getDimensions()
	pattern, quads = scrollPattern(basePattern, 50, 0)
	stereogram = Stereogram:new(pattern, w, h)
	stereogram:setSeparation(270, 220)
	player = { x = 800, y = 500, dx = 0, dy = 0 }
	stereo = true
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
	local dx, dy = scancodeStick('right', 'left', 'down', 'up')
	local accel = 500
	player.dx = player.dx + dt * dx * accel
	player.dy = player.dy + dt * dy * accel
	player.x = player.x + dt * player.dx
	player.y = player.y + dt * player.dy
end

local function drawGrayscaleGame()
	local canvas = love.graphics.getCanvas()
	local w, h
	if canvas then w, h = canvas:getDimensions()
	else w, h = love.graphics.getDimensions() end
	local dx, dy = w/2 - player.x, h/2 - player.y
	love.graphics.translate(dx, dy)
	local g = 32
	local x0 = math.floor((player.x - w/2) / g)
	local x1 = math.ceil((player.x + w/2) / g)
	local y0 = math.floor((player.y - h/2) / g)
	local y1 = math.ceil((player.y + h/2) / g)
	for ix=x0,x1 do
		for iy=y0,y1 do
			local gray = 0.2 * love.math.noise(0.1*ix, 0.1*iy)
			love.graphics.setColor(gray, gray, gray)
			love.graphics.rectangle('fill', ix*g, iy*g, g, g)
		end
	end
	return dx, dy
end

function love.draw()
	local wWindow, hWindow = love.graphics.getDimensions()
	if stereo then
		stereogram:resize(wWindow, hWindow, 0, 0)
		stereogram:setHeightMap()
		love.graphics.clear(0, 0, 0)
	end
	local dx, dy = drawGrayscaleGame()

	if stereo then
		scrollPattern(basePattern, dx, dy, pattern, quads)
		love.graphics.setCanvas()
		love.graphics.origin()
		love.graphics.setColor(1, 1, 1)
		-- love.graphics.draw(pattern, 0, 0) -- XXX
		love.graphics.draw(stereogram:render(), 0, 0)
	end
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
	elseif k == 'space' then
		stereo = not stereo
	end
end
