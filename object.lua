local object = {}

local vertdefs = require("vertdefs")
local vec3 = require("vec3")
local mat3 = require("mat3")

--returns a 4x4 transformation matrix to be passed to the vertex shader
local function computetransforms(vertT, normT, pos, rot, scale)
	local px, py, pz = pos:dump()
	local
		xx, yx, zx,
		xy, yy, zy,
		xz, yz, zz = rot:dump()
	local sx, sy, sz = scale:dump()
	--mat3(scale)*rot
	vertT[1]  = sx*xx
	vertT[2]  = sy*yx
	vertT[3]  = sz*zx
	vertT[4]  = px
	vertT[5]  = sx*xy
	vertT[6]  = sy*yy
	vertT[7]  = sz*zy
	vertT[8]  = py
	vertT[9]  = sx*xz
	vertT[10] = sy*yz
	vertT[11] = sz*zz
	vertT[12] = pz
	--transpose(det(vertT)*inverse(vertT))
	normT[1]  = sy*sz*(yy*zz - yz*zy)
	normT[2]  = sx*sz*(xz*zy - xy*zz)
	normT[3]  = sx*sy*(xy*yz - xz*yy)
	normT[5]  = sy*sz*(yz*zx - yx*zz)
	normT[6]  = sx*sz*(xx*zz - xz*zx)
	normT[7]  = sx*sy*(xz*yx - xx*yz)
	normT[9]  = sy*sz*(yx*zy - yy*zx)
	normT[10] = sx*sz*(xy*zx - xx*zy)
	normT[11] = sx*sy*(xx*yy - xy*yx)
end

local function newobject(mesh)
	local pos = vec3.null
	local rot = mat3.identity
	local scale = vec3.new(1, 1, 1)
	local color = vec3.new(1, 1, 1)

	local changed = false

	local vertT = {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1,
	}
	local normT = {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1,
	}
	local colorT = {
		1, 1, 1,
	}

	local self = {}

	function self.setpos(newpos)
		changed = true
		pos = newpos
	end

	function self.setrot(newrot)
		changed = true
		rot = newrot
	end

	function self.setscale(newscale)
		changed = true
		scale = newscale
	end

	function self.setcolor(newcolor)
		changed = true
		color = newcolor
	end

	function self.getdrawdata()
		if changed then
			changed = false
			computetransforms(vertT, normT, pos, rot, scale)
			colorT[1] = color.x
			colorT[2] = color.y
			colorT[3] = color.z
		end
		return mesh, vertT, normT, colorT
	end

	return self
end

local meshdefs = {}

function object.load(name, verts)
	meshdefs[name] = love.graphics.newMesh(vertdefs.mesh, verts, "triangles", "static")
end

function object.new(name)
	return newobject(meshdefs[name])
end












--BEYOND THIS LIES CODE FOR SIMPLE OBJECTS
--SPHERES, BOXES, TETRAHEDRONS








local spheredefs = {}

function object.newsphere(n)
	if not spheredefs[n] then
		--outer radius of 1:
		local u = ((5 - 5^0.5)/10)^0.5
		local v = ((5 + 5^0.5)/10)^0.5
		--inner radius of 1:
		--local u = (3/2*(7 - 3*5^0.5))^0.5
		--local v = (3/2*(3 - 5^0.5))^0.5
		local a = vec3.new( 0,  u,  v)
		local b = vec3.new( 0,  u, -v)
		local c = vec3.new( 0, -u,  v)
		local d = vec3.new( 0, -u, -v)
		local e = vec3.new( v,  0,  u)
		local f = vec3.new(-v,  0,  u)
		local g = vec3.new( v,  0, -u)
		local h = vec3.new(-v,  0, -u)
		local i = vec3.new( u,  v,  0)
		local j = vec3.new( u, -v,  0)
		local k = vec3.new(-u,  v,  0)
		local l = vec3.new(-u, -v,  0)
		local tris = {
			{a, i, k},
			{b, k, i},
			{c, l, j},
			{d, j, l},

			{e, a, c},
			{f, c, a},
			{g, d, b},
			{h, b, d},

			{i, e, g},
			{j, g, e},
			{k, h, f},
			{l, f, h},

			{a, e, i},
			{a, k, f},
			{b, h, k},
			{b, i, g},
			{c, f, l},
			{c, j, e},
			{d, g, j},
			{d, l, h},
		}

		local vertices = {}

		local function interp(a, b, c, n, i, j)
			return i/n*b + j/n*c - (i + j - n)/n*a
		end

		for l = 1, 20 do
			for i = 0, n - 1 do
				for j = 0, n - i - 1 do
					local a = tris[l][1]
					local b = tris[l][2]
					local c = tris[l][3]

					local u = interp(a, b, c, n, i, j):unit()
					local v = interp(a, b, c, n, i + 1, j):unit()
					local w = interp(a, b, c, n, i, j + 1):unit()
					vertices[#vertices + 1] = {u.x, u.y, u.z, u.x, u.y, u.z, 1, 1, 1, 1, 0, 0}
					vertices[#vertices + 1] = {v.x, v.y, v.z, v.x, v.y, v.z, 1, 1, 1, 1, 0, 0}
					vertices[#vertices + 1] = {w.x, w.y, w.z, w.x, w.y, w.z, 1, 1, 1, 1, 0, 0}
				end
			end
			for i = 1, n - 1 do
				for j = 1, n - i do
					local a = tris[l][1]
					local b = tris[l][2]
					local c = tris[l][3]

					local u = interp(a, b, c, n, i, j):unit()
					local v = interp(a, b, c, n, i - 1, j):unit()
					local w = interp(a, b, c, n, i, j - 1):unit()
					vertices[#vertices + 1] = {u.x, u.y, u.z, u.x, u.y, u.z, 1, 1, 1, 1, 0, 0}
					vertices[#vertices + 1] = {v.x, v.y, v.z, v.x, v.y, v.z, 1, 1, 1, 1, 0, 0}
					vertices[#vertices + 1] = {w.x, w.y, w.z, w.x, w.y, w.z, 1, 1, 1, 1, 0, 0}
				end
			end
		end

		spheredefs[n] = love.graphics.newMesh(vertdefs.mesh, vertices, "triangles", "static")
	end

	return newobject(spheredefs[n])
end

local boxmesh do
	local vertices = {
		{ 1,  1,  1,  1,  0,  0, 1, 1, 1, 1, 0, 0},
		{ 1, -1,  1,  1,  0,  0, 1, 1, 1, 1, 0, 0},
		{ 1,  1, -1,  1,  0,  0, 1, 1, 1, 1, 0, 0},
		{ 1,  1,  1,  0,  1,  0, 1, 1, 1, 1, 0, 0},
		{ 1,  1, -1,  0,  1,  0, 1, 1, 1, 1, 0, 0},
		{-1,  1,  1,  0,  1,  0, 1, 1, 1, 1, 0, 0},
		{ 1,  1,  1,  0,  0,  1, 1, 1, 1, 1, 0, 0},
		{-1,  1,  1,  0,  0,  1, 1, 1, 1, 1, 0, 0},
		{ 1, -1,  1,  0,  0,  1, 1, 1, 1, 1, 0, 0},


		{-1,  1, -1, -1,  0,  0, 1, 1, 1, 1, 0, 0},
		{-1, -1, -1, -1,  0,  0, 1, 1, 1, 1, 0, 0},
		{-1,  1,  1, -1,  0,  0, 1, 1, 1, 1, 0, 0},
		{-1,  1, -1,  0,  1,  0, 1, 1, 1, 1, 0, 0},
		{-1,  1,  1,  0,  1,  0, 1, 1, 1, 1, 0, 0},
		{ 1,  1, -1,  0,  1,  0, 1, 1, 1, 1, 0, 0},
		{-1,  1, -1,  0,  0, -1, 1, 1, 1, 1, 0, 0},
		{ 1,  1, -1,  0,  0, -1, 1, 1, 1, 1, 0, 0},
		{-1, -1, -1,  0,  0, -1, 1, 1, 1, 1, 0, 0},


		{ 1, -1, -1,  0,  0, -1, 1, 1, 1, 1, 0, 0},
		{-1, -1, -1,  0,  0, -1, 1, 1, 1, 1, 0, 0},
		{ 1,  1, -1,  0,  0, -1, 1, 1, 1, 1, 0, 0},
		{ 1, -1, -1,  1,  0,  0, 1, 1, 1, 1, 0, 0},
		{ 1,  1, -1,  1,  0,  0, 1, 1, 1, 1, 0, 0},
		{ 1, -1,  1,  1,  0,  0, 1, 1, 1, 1, 0, 0},
		{ 1, -1, -1,  0, -1,  0, 1, 1, 1, 1, 0, 0},
		{ 1, -1,  1,  0, -1,  0, 1, 1, 1, 1, 0, 0},
		{-1, -1, -1,  0, -1,  0, 1, 1, 1, 1, 0, 0},


		{-1, -1,  1,  0, -1,  0, 1, 1, 1, 1, 0, 0},
		{-1, -1, -1,  0, -1,  0, 1, 1, 1, 1, 0, 0},
		{ 1, -1,  1,  0, -1,  0, 1, 1, 1, 1, 0, 0},
		{-1, -1,  1,  0,  0,  1, 1, 1, 1, 1, 0, 0},
		{ 1, -1,  1,  0,  0,  1, 1, 1, 1, 1, 0, 0},
		{-1,  1,  1,  0,  0,  1, 1, 1, 1, 1, 0, 0},
		{-1, -1,  1, -1,  0,  0, 1, 1, 1, 1, 0, 0},
		{-1,  1,  1, -1,  0,  0, 1, 1, 1, 1, 0, 0},
		{-1, -1, -1, -1,  0,  0, 1, 1, 1, 1, 0, 0},
	}

	boxmesh = love.graphics.newMesh(vertdefs.mesh, vertices, "triangles", "static")
end

function object.newbox()
	return newobject(boxmesh)
end

local tetmesh do
	local n = 1/3^(1/2)
	--a = { n,  n,  n}
	--b = {-n,  n, -n}
	--c = { n, -n, -n}
	--d = {-n, -n,  n}
	local vertices = {
		{-n,  n, -n, -n, -n, -n, 1, 1, 1, 1, 0, 0},--b
		{ n, -n, -n, -n, -n, -n, 1, 1, 1, 1, 0, 0},--c
		{-n, -n,  n, -n, -n, -n, 1, 1, 1, 1, 0, 0},--d

		{ n,  n,  n,  n, -n,  n, 1, 1, 1, 1, 0, 0},--a
		{-n, -n,  n,  n, -n,  n, 1, 1, 1, 1, 0, 0},--d
		{ n, -n, -n,  n, -n,  n, 1, 1, 1, 1, 0, 0},--c

		{-n, -n,  n, -n,  n,  n, 1, 1, 1, 1, 0, 0},--d
		{ n,  n,  n, -n,  n,  n, 1, 1, 1, 1, 0, 0},--a
		{-n,  n, -n, -n,  n,  n, 1, 1, 1, 1, 0, 0},--b

		{ n, -n, -n,  n,  n, -n, 1, 1, 1, 1, 0, 0},--c
		{-n,  n, -n,  n,  n, -n, 1, 1, 1, 1, 0, 0},--b
		{ n,  n,  n,  n,  n, -n, 1, 1, 1, 1, 0, 0},--a
	}

	tetmesh = love.graphics.newMesh(vertdefs.mesh, vertices, "triangles", "static")
end

function object.newtetrahedron()
	return newobject(tetmesh)
end

return object