//love_Canvases[layer]
//VaryingColor		 = vec4 Color
//MainTex			 = Image Texture
//VaryingTexCoord	 = vec2 TexturePosition
//love_PixelCoord	 = vec2 PixelPosition


/*
uniform vec3 lightorig;
uniform vec3 lightcolor;
*/
uniform mat4 vertT;

uniform Image wverts;
uniform Image wnorms;
uniform Image colors;

uniform vec2 screendim;
uniform vec3 lightcolor;


float pointlightbrightness(float r, vec3 l, vec3 n){
	float d = length(l);
	float c = max(0.0, dot(l, n));
	float s = max(0.0, 1 - d/r);
	return s*c/(d*d*d);
}

void effect(){
	vec2 coords = love_PixelCoord/screendim;

	vec4 color4 = Texel(colors, coords);

	vec3 wvert = Texel(wverts, coords).xyz;
	vec3 wnorm = Texel(wnorms, coords).xyz;
	vec3 color = color4.rgb;
	float drawn = color4.a;

	if(drawn == 0.0){
		love_Canvases[0] = vec4(0.0, 0.0, 0.0, 1.0);
	}else{
		float brightness = pointlightbrightness(vertT[0].x, vertT[3].xyz - wvert, wnorm);

		love_Canvases[0] = vec4(brightness*lightcolor*color, 1.0);
	}
}