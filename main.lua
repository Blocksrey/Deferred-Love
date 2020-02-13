local mat3 = require("mat3")
local vec3 = require("vec3")
local quat = require("quat")
local rand = require("random")

--load in the geometry shader and compositing shader
local geomshader = love.graphics.newShader("geom_pixel_shader.glsl", "geom_vertex_shader.glsl")
local lightshader = love.graphics.newShader("light_pixel_shader.glsl", "light_vertex_shader.glsl")
local compshader = love.graphics.newShader("comp_pixel_shader.glsl")
local debandshader = love.graphics.newShader("deband_pixel_shader.glsl")

local randomsampler = rand.newsampler(256, 256, rand.gaussian4)
--make the buffers
local geombuffer
local compbuffer
local function makebuffers()
	local w, h = love.graphics.getDimensions()

	local depths = love.graphics.newCanvas(w, h, {format = "depth24";})-- readable = true;})
	local wverts = love.graphics.newCanvas(w, h, {format = "rgba32f";})
	local wnorms = love.graphics.newCanvas(w, h, {format = "rgba32f";})
	local colors = love.graphics.newCanvas(w, h, {format = "rgba32f";})

	geombuffer = {
		depthstencil = depths;
		wverts,
		wnorms,
		colors,
	}

	local composite = love.graphics.newCanvas(w, h, {format = "rgba32f";})

	compbuffer = {
		depthstencil = depths;
		composite,
	}
end

makebuffers()

function love.resize()
	makebuffers()
end

love.window.setMode(800, 600, {resizable = true; fullscreen = true;})

--this will allow us to compute the frustum transformation matrix once,
--then send it off to the gpu
--width of the screen plane (screen width / screen height)
--height of the screen plane (1 = 90 degree fov)
--near clipping plane distance (positive)
--far clipping plane distance (positive)
--pos (vec3 camera position)
--rot (mat3 camera rotation)
--returns a 4x4 transformation matrix to be passed to the vertex shader
local function getfrusT(width, height, near, far, pos, rot)
	local px, py, pz = pos.x, pos.y, pos.z
	local xx, yx, zx, xy, yy, zy, xz, yz, zz =	rot.xx, rot.yx, rot.zx,
												rot.xy, rot.yy, rot.zy,
												rot.xz, rot.yz, rot.zz
	local xmul = 1/width
	local ymul = 1/height
	local zmul = (far + near)/(far - near)
	local zoff = (2*far*near)/(far - near)
	local rx = px*xx + py*xy + pz*xz
	local ry = px*yx + py*yy + pz*yz
	local rz = px*zx + py*zy + pz*zz
	return {
		xmul*xx, xmul*xy, xmul*xz, -xmul*rx,
		ymul*yx, ymul*yy, ymul*yz, -ymul*ry,
		zmul*zx, zmul*zy, zmul*zz, -zmul*rz - zoff,
		zx,      zy,      zz,      -rz
	}
end


--returns a 4x4 transformation matrix to be passed to the vertex shader
local function computetransforms(vertT, normT, pos, rot, scale)
	--mat3(scale)*rot
	vertT[1]  = scale.x*rot.xx
	vertT[2]  = scale.y*rot.yx
	vertT[3]  = scale.z*rot.zx
	vertT[4]  = pos.x
	vertT[5]  = scale.x*rot.xy
	vertT[6]  = scale.y*rot.yy
	vertT[7]  = scale.z*rot.zy
	vertT[8]  = pos.y
	vertT[9]  = scale.x*rot.xz
	vertT[10] = scale.y*rot.yz
	vertT[11] = scale.z*rot.zz
	vertT[12] = pos.z
	--transpose(det(vertT)*inverse(vertT))
	normT[1]  = scale.y*scale.z*(rot.yy*rot.zz - rot.yz*rot.zy)
	normT[2]  = scale.y*scale.z*(rot.xz*rot.zy - rot.xy*rot.zz)
	normT[3]  = scale.y*scale.z*(rot.xy*rot.yz - rot.xz*rot.yy)
	normT[5]  = scale.x*scale.z*(rot.yz*rot.zx - rot.yx*rot.zz)
	normT[6]  = scale.x*scale.z*(rot.xx*rot.zz - rot.xz*rot.zx)
	normT[7]  = scale.x*scale.z*(rot.xz*rot.yx - rot.xx*rot.yz)
	normT[9]  = scale.x*scale.y*(rot.yx*rot.zy - rot.yy*rot.zx)
	normT[10] = scale.x*scale.y*(rot.xy*rot.zx - rot.xx*rot.zy)
	normT[11] = scale.x*scale.y*(rot.xx*rot.yy - rot.xy*rot.yx)
end

local function newobject(mesh)
	local pos = vec3.null
	local rot = mat3.identity
	local scale = vec3.new(1, 1, 1)

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

	function self.getdrawdata()
		if changed then
			changed = false
			computetransforms(vertT, normT, pos, rot, scale)
		end
		return mesh, vertT, normT
	end

	return self
end

--basic definition
local vertdef = {
	{"VertexPosition", "float", 3},
	{"norm", "float", 3},
	{"VertexColor", "byte", 4},
	{"VertexTexCoord", "float", 2},
}

local function newtet(r, g, b)
	local n = 1/3^(1/2)
	--a = { n,  n,  n}
	--b = {-n,  n, -n}
	--c = { n, -n, -n}
	--d = {-n, -n,  n}
	local vertices = {}
	for i = 1, 1 do
		local ox = 0--math.random()*50 - 25
		local oy = 0--math.random()*50 - 25
		local oz = 0--math.random()*50 - 25
		vertices[#vertices + 1] = {ox + -n, oy +  n, oz + -n, -n, -n, -n, r, g, b, 1, 0, 0}--b
		vertices[#vertices + 1] = {ox +  n, oy + -n, oz + -n, -n, -n, -n, r, g, b, 1, 0, 0}--c
		vertices[#vertices + 1] = {ox + -n, oy + -n, oz +  n, -n, -n, -n, r, g, b, 1, 0, 0}--d

		vertices[#vertices + 1] = {ox +  n, oy +  n, oz +  n,  n, -n,  n, r, g, b, 1, 0, 0}--a
		vertices[#vertices + 1] = {ox + -n, oy + -n, oz +  n,  n, -n,  n, r, g, b, 1, 0, 0}--d
		vertices[#vertices + 1] = {ox +  n, oy + -n, oz + -n,  n, -n,  n, r, g, b, 1, 0, 0}--c

		vertices[#vertices + 1] = {ox + -n, oy + -n, oz +  n, -n,  n,  n, r, g, b, 1, 0, 0}--d
		vertices[#vertices + 1] = {ox +  n, oy +  n, oz +  n, -n,  n,  n, r, g, b, 1, 0, 0}--a
		vertices[#vertices + 1] = {ox + -n, oy +  n, oz + -n, -n,  n,  n, r, g, b, 1, 0, 0}--b

		vertices[#vertices + 1] = {ox +  n, oy + -n, oz + -n,  n,  n, -n, r, g, b, 1, 0, 0}--c
		vertices[#vertices + 1] = {ox + -n, oy +  n, oz + -n,  n,  n, -n, r, g, b, 1, 0, 0}--b
		vertices[#vertices + 1] = {ox +  n, oy +  n, oz +  n,  n,  n, -n, r, g, b, 1, 0, 0}--a
	end
	local mesh = love.graphics.newMesh(vertdef, vertices, "triangles", "static")

	return newobject(mesh)
end


--basic definition
local lightdef = {
	{"VertexPosition", "float", 3},
}

local lightmesh do
	--outer radius is 1:
	--local u = ((5 - 5^0.5)/10)^0.5
	--local v = ((5 + 5^0.5)/10)^0.5
	--inner radius is 1:
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

	lightmesh = love.graphics.newMesh(lightdef, vertices, "triangles", "static")
end

local function newlight()
	local color = vec3.new(1, 1, 1)
	local pos = vec3.null
	local changed = true

	local alpha = 1/64--1/256
	local vertT = {
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 1,
	}
	local lightcolor = {1, 1, 1}

	local self = {}

	function self.setpos(newpos)
		changed = true
		pos = newpos
	end

	function self.setcolor(newcolor)
		changed = true
		color = newcolor
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
			lightcolor[1] = color.x
			lightcolor[2] = color.y
			lightcolor[3] = color.z
		end
		return lightmesh, vertT, lightcolor
	end

	return self
end

--for the sake of my battery life
--love.window.setVSync(false)

local wut = 0
local function drawmeshes(frusT, meshes, lights)
	local w, h = love.graphics.getDimensions()
	love.graphics.push("all")
	love.graphics.reset()

	--PREPARE FOR GEOMETRY
	love.graphics.setBlendMode("replace")
	love.graphics.setMeshCullMode("back")
	love.graphics.setDepthMode("less", true)
	love.graphics.setCanvas(geombuffer)
	love.graphics.setShader(geomshader)
	love.graphics.clear()

	--RENDER GEOMETRY
	geomshader:send("frusT", frusT)
	for i = 1, #meshes do
		local mesh, vertT, normT = meshes[i].getdrawdata()
		geomshader:send("vertT", vertT)
		geomshader:send("normT", normT)
		love.graphics.draw(mesh)
	end

	--PREPARE FOR LIGHTING
	love.graphics.reset()
	love.graphics.setBlendMode("add")
	love.graphics.setMeshCullMode("front")
	love.graphics.setDepthMode("greater", false)
	love.graphics.setShader(lightshader)
	love.graphics.setCanvas(compbuffer)
	love.graphics.clear(0, 0, 0, 1, false, false)

	--RENDER LIGHTING
	lightshader:send("screendim", {w, h})
	lightshader:send("frusT", frusT)
	lightshader:send("wverts", geombuffer[1])
	lightshader:send("wnorms", geombuffer[2])
	lightshader:send("colors", geombuffer[3])
	for i = 1, #lights do
		local mesh, vertT, color = lights[i].getdrawdata()
		lightshader:send("vertT", vertT)
		lightshader:send("lightcolor", color)
		love.graphics.draw(mesh)
	end
	--]]
	--[[love.graphics.setDepthMode()
	love.graphics.setShader(compshader)
	love.graphics.setCanvas(compbuffer)
	compshader:send("wverts", geombuffer[1])
	compshader:send("wnorms", geombuffer[2])
	love.graphics.draw(geombuffer[3])]]

	love.graphics.reset()--just to make sure
	--love.graphics.rectangle("fill", 0, 0, w, h)
	love.graphics.setShader(debandshader)
	do
		local image, size, offset = randomsampler.getdrawdata()
		debandshader:send("randomimage", image)
		debandshader:send("randomsize", size)
		debandshader:send("randomoffset", offset)
	end
	debandshader:send("screendim", {w, h})
	debandshader:send("finalcanvas", compbuffer[1])
	debandshader:send("wut", wut)
	love.graphics.setCanvas()
	love.graphics.draw(compbuffer[1])--just straight up color

	love.graphics.pop()
end




























love.mouse.setRelativeMode(true)

local near = 1/10
local far = 5000
local pos = vec3.new(0, 0, -5)
local angy = 0
local angx = 0
local sens = 1/256
local speed = 8

function love.keypressed(k)
	if k == "escape" then
		love.event.quit()
	elseif k == "r" then
		wut = 1 - wut
	end
end

local function clamp(p, a, b)
	return p < a and a or p > b and b or p
end


local pi = math.pi

function love.mousemoved(px, py, dx, dy)
	angy = angy + sens*dx
	angx = angx + sens*dy
	angx = clamp(angx, -pi/2, pi/2)
end

function love.update(dt)
	local rot = mat3.fromeuleryxz(angy, angx, 0)

	local keyd = love.keyboard.isDown("d") and 1 or 0
	local keya = love.keyboard.isDown("a") and 1 or 0
	local keye = love.keyboard.isDown("e") and 1 or 0
	local keyq = love.keyboard.isDown("q") and 1 or 0
	local keyw = love.keyboard.isDown("w") and 1 or 0
	local keys = love.keyboard.isDown("s") and 1 or 0

	local vel = rot*vec3.new(keyd - keya, keye - keyq, keyw - keys):unit()
	pos = pos + dt*speed*vel
end



local meshes = {}
local lights = {}
--meshes[2] = newlightico()

for i = 1, 1000 do
	meshes[i] = newtet(1, 1, 1)
	meshes[i].setpos(vec3.new(
		(math.random() - 1/2)*20,
		(math.random() - 1/2)*20,
		(math.random() - 1/2)*20
	))
	meshes[i].setrot(mat3.random())
end

for i = 1, 10 do
	lights[i] = newlight()
	lights[i].setpos(vec3.new(
		(math.random() - 1/2)*20,
		(math.random() - 1/2)*20,
		(math.random() - 1/2)*20
	))
	lights[i].setcolor(vec3.new(
		math.random()*10,
		math.random()*10,
		math.random()*10
	))
	--lights[i].setrot(mat3.random())
end



function love.draw()
	local w, h = love.graphics.getDimensions()

	local t = love.timer.getTime()--tick()
	local rot = mat3.fromeuleryxz(angy, angx, 0)
	local frusT = getfrusT(w/h, 1, near, far, pos, rot)

	--meshes[1].setrot(mat3.fromeuleryxz(t, 0, 0))


	--[[for i = 1, #meshes do
		meshes[i].setscale(vec3.new(
			math.cos(t) + 1,
			math.cos(t + 2*pi/3) + 1,
			math.cos(t + 4*pi/3) + 1
		))
		--meshes[i].setrot(mat3.fromquat(quat.random()))
	end]]

	drawmeshes(frusT, meshes, lights)
	--love.graphics.print((love.timer.getTime() - t)*1000)
	love.graphics.print(
		select(2, lights[1].getdrawdata())[1]
	)
	--love.graphics.print(love.timer.getFPS())

	love.window.setTitle(love.timer.getFPS())
end