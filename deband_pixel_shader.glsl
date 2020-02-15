//THIS IS THE FINAL PASS
//THIS RENDERS TO THE SCREEN
//WE USE Y-INVERTED COORDINATES

uniform Image finalcanvas;
uniform vec2 screendim;

uniform Image randomimage;
uniform vec2 randomsize;
uniform vec2 randomoffset;


uniform float wut;

vec4 rand(vec2 xy){
	vec2 unitcoord = (xy + randomoffset)/randomsize;
	return Texel(randomimage, mod(unitcoord, 1.0));
}

//Just an equation I found on the internet
vec3 filmicToneMapping(vec3 color){
	color = max(vec3(0.0), color - vec3(0.004));
	color = (color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}

const float accuracy = 1.0/256.0;

void effect(){
	//compute inverted coordinates
	vec2 coords = love_PixelCoord/screendim;
	coords = vec2(coords.x, 1.0 - coords.y);
	vec3 basecolor = Texel(finalcanvas, coords).rgb;

	//int i = int(2.0*coords.x);

	//vec3 mappedcolor;
	//if (i == 0) mappedcolor = filmicToneMapping(basecolor);
	//if (i == 1) mappedcolor = whatever(basecolor);
	//if (i == 1) mappedcolor = whatever(basecolor);
	//if (i == 3) mappedcolor = basecolor;
	vec3 mappedcolor = filmicToneMapping(basecolor);
	vec3 noise = wut*accuracy*rand(love_PixelCoord).rgb;
	vec3 finalcolor = mappedcolor + noise + accuracy/2.0;
	love_Canvases[0] = vec4(finalcolor - mod(finalcolor, accuracy), 1.0);//write to screen
}



/*float rand(vec2 co){
	//Found this on the internet
	//This will be replaced in the future

	float z0 = fract(sin(dot(co, vec2(12.9898, 78.233)) + t*0.00231498)*43758.5453);
	float z1 = fract(sin(dot(co, vec2(12.9898, -78.233)) + t*0.00231498)*43758.5453);
	return wut*(z0 + z1 - 1.0);

	//this converts the above internet thing into a gaussian distribution
	//return wut*sqrt(-2*log(1.0 - z0))*cos(6.28318*z1);
}*/