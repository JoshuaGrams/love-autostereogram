local Stereogram = {}

local shader = false

function Stereogram.new(class, pattern, w, h, x, y)
	local obj = setmetatable({}, class)
	obj.pattern = pattern
	local pw, ph = pattern:getDimensions()
	obj.separation = math.max(pw, 64)
	obj.minSeparation = 32
	obj:resize(w, h, x, y)
	if not shader then
		shader = love.graphics.newShader('stereogram.glsl')
	end
	obj.shader = shader
	return obj
end
Stereogram.__call = Stereogram.new
Stereogram.__index = Stereogram

local function newQuads(self)
	local sep, min = self.separation, self.minSeparation
	local w, h = self.w - sep, self.h
	self.quads = {}
	for qx=0,w,min do
		local qw = math.min(min, w - qx)
		local q = love.graphics.newQuad(qx, 0, qw, h, w, h)
		table.insert(self.quads, q)
	end
end

local function newCanvasesAndQuads(self)
	if self.canvas then self.canvas:release() end
	if self.heightMap then self.heightMap:release() end
	self.canvas = love.graphics.newCanvas(self.w, self.h)
	self.heightMap = love.graphics.newCanvas(self.w - self.separation, self.h)
	newQuads(self)
end

function Stereogram.resize(self, w, h, x, y)
	self.x, self.y = x or 0, y or 0
	local wPrev, hPrev = false, false
	if self.canvas then
		wPrev, hPrev = self.canvas:getDimensions()
	end
	if w ~= wPrev or h ~= hPrev then
		self.w, self.h = w, h
		newCanvasesAndQuads(self)
	end
end

function Stereogram.setSeparation(self, separation, minSeparation)
	separation = math.max(separation or self.separation, 64)
	minSeparation = math.max(minSeparation or self.minSeparation, 32)
	local sep, min = self.separation, self.minSeparation
	if separation ~= sep or minSeparation ~= min then
		self.separation = separation
		self.minSeparation = minSeparation
		newCanvasesAndQuads(self)
	end
end

function Stereogram.setHeightMap(self)
	love.graphics.setCanvas(self.heightMap)
end

local function drawPattern(self)
	local pw, ph = self.pattern:getDimensions()
	local xScale = self.separation / pw
	for y=0,self.h-1,ph do
		love.graphics.draw(self.pattern, self.x, y + self.y, 0, xScale, 1)
	end
end

function Stereogram.render(self)
	local oldColor = {love.graphics.getColor()}
	local oldShader = love.graphics.getShader()
	local oldCanvas = love.graphics.getCanvas()

	-- Render to our canvas (can't read from default framebuffer).
	love.graphics.setCanvas(self.canvas)

	-- Draw pattern with default shader.
	love.graphics.setShader()
	love.graphics.setColor(1, 1, 1)
	drawPattern(self)

	-- Draw height map strips with stereogram shader. 
	if not self.debug then
		love.graphics.setShader(self.shader)
		self.shader:send('canvas', self.canvas)
		self.shader:send('separation', self.separation / self.w)
		self.shader:send('minSeparation', self.minSeparation / self.w)
		self.shader:send('xScale', (self.w - self.separation) / self.w)
	end
	local w = self.minSeparation
	local x0 = self.x + self.separation - w  -- `-w` for 1-based indexing.
	for i,q in ipairs(self.quads) do
		love.graphics.draw(self.heightMap, q, x0 + i * w, self.y)
	end

	-- Reset drawing state, return canvas to caller.
	love.graphics.setCanvas(oldCanvas)
	love.graphics.setShader(oldShader)
	love.graphics.setColor(oldColor)
	
	return self.canvas
end

return Stereogram
