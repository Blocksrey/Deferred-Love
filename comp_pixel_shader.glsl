//love_Canvases[layer]
//VaryingColor		 = vec4 Color
//MainTex			 = Image Texture
//VaryingTexCoord	 = vec2 TexturePosition
//love_PixelCoord	 = vec2 PixelPosition

uniform Image wverts;
uniform Image wnorms;
//uniform Image colors;
//varying Image MainTex;

//uniform float w, h;

const vec3 mask = vec3(0.0, 1.0, -1.0);

const vec4 atmoscolor = vec4(0.6, 0.85, 0.92, 1.0);
const vec4 pointcolor = vec4(0.5, 1.0, 0.5, 1.0);

const vec3 pointpos = vec3(0.0, 5.0, 0.0);

float hemibrightness(float d){
	return 0.5*d + 0.5;
}
float pointlightbrightness(vec3 l, vec3 n){
	return max(0.0, dot(l, n))/pow(dot(l, l), 1.5);
}

vec4 effect(vec4 Color, Image colors, vec2 coords, vec2 PixelPosition){
	vec3 wvert = Texel(wverts, coords).xyz;
	vec3 wnorm = Texel(wnorms, coords).xyz;
	vec4 color = Texel(colors, coords);

	vec4 lightatmos = hemibrightness(wnorm.y)*atmoscolor;
	vec4 lightpoint = 100.0*pointlightbrightness(pointpos - wvert, wnorm)*pointcolor;

	return vec4(((lightatmos + lightpoint)*color).rgb, 1.0);
}