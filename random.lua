--[[
random.uniform()
random.uniform2()
random.uniform3()
random.uniform4()
	return uniform random variables between 0 and 1

random.gaussian()
random.gaussian2()
random.gaussian3()
random.gaussian4()
	return gaussian random variables with a sigma of 1

random.unit()
random.unit2()
random.unit3()
random.unit4()
	return random variables whose magnitude is 1

random.newsampler(width, height, generator)
	returns an object with a image which can be sampled from
	width and height are the dimensions of the image
	generator is a function which returns up to 4 random variables

	sampler.getdrawdata()
		returns
			image,
			size,
			randomoffset
]]

local random = {}

local log = require("log")
local rand = math.random
local tau = 2*math.pi
local cos = math.cos
local sin = math.sin
local ln = math.log

function random.uniform()
	return rand()
end

function random.uniform2()
	return
		rand(),
		rand()
end

function random.uniform3()
	return
		rand(),
		rand(),
		rand()
end

function random.uniform4()
	return
		rand(),
		rand(),
		rand(),
		rand()
end

function random.gaussian2()
	local m = (-2*ln(1 - rand()))^0.5
	local a = tau*rand()
	return
		m*cos(a),
		m*sin(a)
end

random.gaussian = random.gaussian2

function random.gaussian4()
	local m0 = (-2*ln(1 - rand()))^0.5
	local m1 = (-2*ln(1 - rand()))^0.5
	local a0 = tau*rand()
	local a1 = tau*rand()
	return
		m0*cos(a0),
		m0*sin(a0),
		m1*cos(a1),
		m1*sin(a1)
end

random.gaussian3 = gaussian4

function random.unit()
	if rand() < 0.5 then
		return -1
	else
		return 1
	end
end

function random.unit2()
	local a = tau*rand()
	return
		cos(a),
		sin(a)
end

function random.unit3()
	local x = 2*rand() - 1
	local i = (1 - x*x)^0.5
	local a = tau*rand()
	return
		x,
		i*cos(a),
		i*sin(a)
end

function random.unit4()
	local l0 = ln(1 - rand())
	local l1 = ln(1 - rand())
	local m0 = (l0/(l0 + l1))^0.5
	local m1 = (l1/(l0 + l1))^0.5
	local a0 = tau*rand()
	local a1 = tau*rand()
	return 
		m0*cos(a0),
		m0*sin(a0),
		m1*cos(a1),
		m1*sin(a1)
end

function random.triangular()
	return
		rand() + rand() - 1
end

function random.triangular2()
	return
		rand() + rand() - 1,
		rand() + rand() - 1
end

function random.triangular3()
	return
		rand() + rand() - 1,
		rand() + rand() - 1,
		rand() + rand() - 1
end

function random.triangular4x2()
	return
		2*(rand() + rand() - 1),
		2*(rand() + rand() - 1),
		2*(rand() + rand() - 1),
		2*(rand() + rand() - 1)
end

function random.triangular4()
	return
		(rand() + rand() - 1),
		(rand() + rand() - 1),
		(rand() + rand() - 1),
		(rand() + rand() - 1)
end

--just make some random values that the buffers can use
function random.newsampler(w, h, generator)
	local self = {}
	local data = love.image.newImageData(w, h, "rgba32f")

	if not generator then
		generator = random.uniform4
	end
	--uniform random variables can be transformed into other random variables with some effort

	for i = 0, w - 1 do
		for j = 0, h - 1 do
			data:setPixel(i, j, generator())
		end
	end

	local image = love.graphics.newImage(data)
	local size = {w, h}
	local offset = {0, 0}

	function self.getdrawdata()
		offset[1] = rand(w) - 1
		offset[2] = rand(h) - 1
		return
			image,
			size,
			offset
	end

	return self
end

return random