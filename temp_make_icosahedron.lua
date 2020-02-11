local a, b, c = 1, 0, 0
--[[
a b c
c a b
b c a
]]

local verts = {}

local n = 0
local names = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l",}

for i = 1, 3 do
	for j = 0, 1 do
		for k = 0, 1 do
			local x = 0
			local y = (-1)^j
			local z = (-1)^k*2
			n = n + 1
			verts[n] = {
				names[n],
				a*x + b*y + c*z,
				c*x + a*y + b*z,
				b*x + c*y + a*z,
			}
		end
	end
	a, b, c = b, c, a
end

for i = 1, #verts do
	print(unpack(verts[i]))
end
--[[
a,i,k,
b,k,i,
c,l,j,
d,j,l,

e,a,c,
f,c,a,
g,d,b,
h,b,d,

i,e,g,
j,g,e,
k,h,f,
l,f,h,

a,e,i,
a,k,f,
b,h,k,
b,i,g,
c,f,l,
c,j,e,
d,g,j,
d,l,h,



]]


--[[
buffers:
	depthbuff (depth buffer)
	colorbuff
	wvertbuff
	wnormbuff
	finalbuff


draw (replace) geometry to depthbuff, colorbuff, wvertbuff, wnormbuff
draw (replace) skybox and ambient to finalbuff
draw (add) lighting geometry to finalbuff
effects like blur?

geombuffer
	geom shader
	renders geometry to buffer
light shader
	renders light geometry to light buffer
composite shader


]]