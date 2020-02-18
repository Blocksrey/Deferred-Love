local light = {}

local vertdefs = require("vertdefs")
local vec3 = require("vec3")
local mat3 = require("mat3")

local lightmesh do
	--outer radius of 1:
	--local u = ((5 - 5^0.5)/10)^0.5
	--local v = ((5 + 5^0.5)/10)^0.5
	--inner radius of 1:
	local u = (3/2*(7 - 3*5^0.5))^0.5
	local v = (3/2*(3 - 5^0.5))^0.5
	local a = { 0,  u,  v}
	local b = { 0,  u, -v}
	local c = { 0, -u,  v}
	local d = { 0, -u, -v}
	local e = { v,  0,  u}
	local f = {-v,  0,  u}
	local g = { v,  0, -u}
	local h = {-v,  0, -u}
	local i = { u,  v,  0}
	local j = { u, -v,  0}
	local k = {-u,  v,  0}
	local l = {-u, -v,  0}
	local vertices = {
		a, i, k,
		b, k, i,
		c, l, j,
		d, j, l,

		e, a, c,
		f, c, a,
		g, d, b,
		h, b, d,

		i, e, g,
		j, g, e,
		k, h, f,
		l, f, h,

		a, e, i,
		a, k, f,
		b, h, k,
		b, i, g,
		c, f, l,
		c, j, e,
		d, g, j,
		d, l, h,
	}

	lightmesh = love.graphics.newMesh(vertdefs.light, vertices, "triangles", "static")
end

function light.new()
	local color = vec3.new(1, 1, 1)
	local pos = vec3.null
	local changed = true

	local alpha = 1/2--1/256
	local vertT = {
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 1,
	}
	local colorT = {1, 1, 1}

	local self = {}

	function self.setpos(newpos)
		changed = true
		pos = newpos
	end

	function self.setcolor(newcolor)
		changed = true
		color = newcolor
	end

	function self.setalpha(newalpha)
		changed = true
		alpha = newalpha
	end

	function self.getpos()
		return pos
	end

	function self.getcolor()
		return color
	end

	function self.getalpha()
		return alpha
	end

	local frequencyscale = vec3.new(0.3, 0.59, 0.11)
	function self.getdrawdata()
		if changed then
			changed = false
			local brightness = frequencyscale:dot(color)
			local radius = (brightness/alpha)^0.5
			vertT[1] = radius
			vertT[4] = pos.x
			vertT[6] = radius
			vertT[8] = pos.y
			vertT[11] = radius
			vertT[12] = pos.z
			colorT[1] = color.x
			colorT[2] = color.y
			colorT[3] = color.z
		end
		return lightmesh, vertT, colorT
	end

	return self
end

return light