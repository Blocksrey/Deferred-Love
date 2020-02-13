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

void effect(){
	//compute inverted coordinates
	vec2 coords = love_PixelCoord/screendim;
	coords = vec2(coords.x, 1.0 - coords.y);
	vec3 color = Texel(finalcanvas, coords).rgb;
	vec3 noise = wut/256.0*rand(love_PixelCoord).rgb;
	love_Canvases[0] = vec4(color + noise, 1.0);//write to screen
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