//THIS IS THE FINAL PASS
//THIS RENDERS TO THE SCREEN
//WE USE Y-INVERTED COORDINATES

uniform float t;
uniform vec2 screendim;
uniform Image prenoise;

uniform float wut;

/*
float frq = 12345.0;//This is the frequency, doesn't really matter
float phi = 1.618033988749895;//this is the golden ratio, the least rational number
float tau = 6.283185307179586;//this makes sine's frequency 1
void rand(float x){
	return mod(sin(tau*frq*x) + phi*frq*x, 1)
}
*/

float rand(vec2 co){
	//Found this on the internet
	//This will be replaced in the future
	float z0 = fract(sin(dot(co, vec2(12.9898, 78.233)) + t*0.00231498)*43758.5453);
	float z1 = fract(sin(dot(co, vec2(12.9898, -78.233)) + t*0.00231498)*43758.5453);
	//this converts the above internet thing into a gaussian distribution
	//return sqrt(-2*log(1.0 - z0))*cos(6.28318*z1);
	return wut*(z0 + z1 - 1.0);
}

void effect(){
	//compute inverted coordinates
	vec2 coords = love_PixelCoord/screendim;
	coords = vec2(coords.x, 1.0 - coords.y);

	//get color
	vec3 color = Texel(prenoise, coords).rgb;

	//compute noise
	vec3 noise = vec3(rand(coords)/256.0);

	//combine
	love_Canvases[0] = vec4(color + noise, 1.0);
}