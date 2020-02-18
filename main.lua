local mat3 = require("mat3")
local vec3 = require("vec3")
local quat = require("quat")
local rand = require("random")
local light = require("light")
local object = require("object")

--load in the geometry shader and compositing shader
local geomshader = love.graphics.newShader("geom_pixel_shader.glsl", "geom_vertex_shader.glsl")
local lightshader = love.graphics.newShader("light_pixel_shader.glsl", "light_vertex_shader.glsl")
local compshader = love.graphics.newShader("comp_pixel_shader.glsl")
local debandshader = love.graphics.newShader("deband_pixel_shader.glsl")

local randomsampler = rand.newsampler(256, 256, rand.triangular4)

--make the buffers
local geombuffer
local compbuffer
local function makebuffers()
	local w, h = love.graphics.getDimensions()

	local depths = love.graphics.newCanvas(w, h, {format = "depth24";})-- readable = true;})
	local wverts = love.graphics.newCanvas(w, h, {format = "rgba32f";})
	local wnorms = love.graphics.newCanvas(w, h, {format = "rgba32f";})
	local colors = love.graphics.newCanvas(w, h, {format = "rgba32f";})

	depths:setFilter("nearest", "nearest")
	wverts:setFilter("nearest", "nearest")
	wnorms:setFilter("nearest", "nearest")
	colors:setFilter("nearest", "nearest")

	geombuffer = {
		depthstencil = depths;
		wverts,
		wnorms,
		colors,
	}

	local composite = love.graphics.newCanvas(w, h, {format = "rgba32f";})

	composite:setFilter("nearest", "nearest")

	compbuffer = {
		depthstencil = depths;
		composite,
	}
end

makebuffers()

function love.resize()
	makebuffers()
end

love.window.setMode(800, 600, {resizable = true; fullscreen = false;})

--this will allow us to compute the frustum transformation matrix once,
--then send it off to the gpu
--ratio of the screen plane (screen width / screen height)
--height of the screen plane (1 = 90 degree fov)
--near clipping plane distance (positive)
--far clipping plane distance (positive)
--pos (vec3 camera position)
--rot (mat3 camera rotation)
--returns a 4x4 transformation matrix to be passed to the vertex shader
local function getfrusT(ratio, height, near, far, pos, rot)
	local px, py, pz = pos.x, pos.y, pos.z
	local xx, yx, zx, xy, yy, zy, xz, yz, zz =	rot.xx, rot.yx, rot.zx,
												rot.xy, rot.yy, rot.zy,
												rot.xz, rot.yz, rot.zz
	local xmul = 1/ratio
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


local newtet = object.newtetrahedron
local newbox = object.newbox
local newsphere = object.newsphere
local newlight = light.new

--for the sake of my battery life
--love.window.setVSync(false)

local wut = 1
local shadow = 0
local function drawmeshes(ratio, height, near, far, pos, rot, meshes, lights)
	local frusT = getfrusT(ratio, height, near, far, pos, rot)
	local w, h = love.graphics.getDimensions()
	love.graphics.push("all")
	love.graphics.reset()

	--PREPARE FOR GEOMETRY
	love.graphics.setWireframe(wut == 0)
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
	lightshader:send("shadow", shadow)
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


























local meshes = {}
local lights = {}

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
	elseif k == "t" then
		shadow = 1 - shadow
	end
end

local yoooo = -48
function love.wheelmoved(x, y)
	if y > 0 then
		yoooo = yoooo - 1
	elseif y < 0 then
		yoooo = yoooo + 1
	end
	for i = 1, #lights do
		lights[i].setalpha(2^(yoooo/8))
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
	love.mouse.setRelativeMode(not love.keyboard.isDown("tab"))

	local mul = speed
	if love.keyboard.isDown("lshift") then
		mul = 8*mul
	end
	if love.keyboard.isDown("lctrl") then
		mul = mul/8
	end

	local rot = mat3.fromeuleryxz(angy, angx, 0)

	local keyd = love.keyboard.isDown("d") and 1 or 0
	local keya = love.keyboard.isDown("a") and 1 or 0
	local keye = love.keyboard.isDown("e") and 1 or 0
	local keyq = love.keyboard.isDown("q") and 1 or 0
	local keyw = love.keyboard.isDown("w") and 1 or 0
	local keys = love.keyboard.isDown("s") and 1 or 0

	local vel = rot*vec3.new(keyd - keya, keye - keyq, keyw - keys):unit()
	pos = pos + dt*mul*vel
end



--meshes[2] = newlightico()

--[[
meshes[1] = newsphere(8, 1, 1, 1)
meshes[2] = newsphere(8, 1, 1, 1)

meshes[1].setscale(vec3.new(0.25, 0.25, 0.25))
meshes[1].setpos(vec3.new(0, 0, 0))
meshes[2].setpos(vec3.new(2, 0, 0))

lights[1] = newlight()
lights[1].setpos(vec3.new(-3, 0, 0))
lights[1].setcolor(vec3.new(10, 10, 10))
--]]

--[[
for i = 1, 50 do
	meshes[i] = newsphere(8, 1, 1, 1)--1280 tris per sphere
	meshes[i].setpos(vec3.new(
		(math.random() - 1/2)*10,
		(math.random() - 1/2)*10,
		(math.random() - 1/2)*10
	))
	meshes[i].setrot(mat3.random())
end
for i = 51, 100 do
	meshes[i] = newtet(1, 1, 1)
	meshes[i].setpos(vec3.new(
		(math.random() - 1/2)*10,
		(math.random() - 1/2)*10,
		(math.random() - 1/2)*10
	))
	meshes[i].setrot(mat3.random())
end

for i = 1, 10 do
	lights[i] = newlight()
	lights[i].setpos(vec3.new(
		(math.random() - 1/2)*100,
		25--(math.random() - 1/2)*10,
		(math.random() - 1/2)*100
	))
	lights[i].setcolor(vec3.new(
		math.random()*100,
		math.random()*100,
		math.random()*100
	))
	lights[i].setalpha(1/64)
end

meshes[1] = newbox(1, 1, 1)
meshes[1].setpos(vec3.new(0, -10, 0))
meshes[1].setscale(vec3.new(40, 1, 40))

--]]

local testmodel = require("test model")
for i = 1, #testmodel do
	local color = testmodel[i][4]
	meshes[i] = newbox(16, color.x, color.y, color.z)
	meshes[i].setpos(testmodel[i][1])
	meshes[i].setrot(testmodel[i][2])
	meshes[i].setscale(testmodel[i][3]/2)
end

--local randomoffset = {}
for i = 1, 100 do
	lights[i] = newlight()
	lights[i].setpos(vec3.new(
		(math.random() - 1/2)*70,
		(math.random())*25,
		(math.random() - 1/2)*70
	))
	--randomoffset[i] = 5*vec3.new(random.unit3())
	lights[i].setcolor(vec3.new(
		math.random()*10,
		math.random()*10,
		math.random()*10
	))
	lights[i].setalpha(1/64)
end



local lastt = love.timer.getTime()
function love.draw()
	local w, h = love.graphics.getDimensions()

	local t = love.timer.getTime()--tick()
	local dt = t - lastt
	local rot = mat3.fromeuleryxz(angy, angx, 0)


	--meshes[1].setrot(mat3.fromeuleryxz(t, 0, 0))


	--[[for i = 1, #meshes do
		meshes[i].setscale(vec3.new(
			rand.uniform3()
		))
		--meshes[i].setrot(mat3.fromquat(quat.random()))
	end]]

	--[=[
	for i = 1, #lights do
		local l = lights[i]
		local pos = l.getpos()
		--local t = (t + i)/10
		--[[if 20 < pos.x then
			pos = pos - vec3.new(40, 0, 0)
			pos.y = math.random()*30 - 15
			pos.z = math.random()*30 - 15
		end
		pos = pos + vec3.new(100*dt, 0, 0)
		l.setpos(pos)]]
		l.setpos(15*vec3.new(math.cos(t + i), 1, math.sin(t + i)))
		--l.setpos(15*vec3.new(math.cos(t + i), math.cos(1.618*t + i), math.cos(2.618*t + i)))
	end
	--]=]

	for i = 1, 1 do
		local tpos = pos + rot*vec3.new(0, 0, 10)
		local lpos = lights[i].getpos()
		local dpos = lpos - tpos
		lights[i].setpos(tpos + 0.01^dt*dpos)
		lights[i].setcolor(vec3.new(5, 5, 5))
	end

	drawmeshes(w/h, 1, near, far, pos, rot, meshes, lights)
	--love.graphics.print((love.timer.getTime() - t)*1000)
	love.graphics.print(
		"debanding enabled: "..wut..
		"\nssshadows enabled: "..shadow..
		"\nlight distance scaler: "..yoooo
		--select(2, lights[1].getdrawdata())[1]
	)
	--love.graphics.print(love.timer.getFPS())

	love.window.setTitle(love.timer.getFPS())
	lastt = t
end