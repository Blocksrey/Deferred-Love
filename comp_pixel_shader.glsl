//compositing shader

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

const vec3 atmoscolor = vec3(0.7, 0.8, 0.95);
const vec3 pointcolor = vec3(0.5, 1.0, 0.5);

const vec3 pointpos = vec3(0.0, 0.0, 0.0);

float hemibrightness(float d){
	return 0.5*d + 0.5;
}

float pointlightbrightness(vec3 l, vec3 n){
	return max(0.0, dot(l, n))/pow(dot(l, l), 1.5);
}

vec4 effect(vec4 Color, Image colors, vec2 coords, vec2 PixelPosition){
	vec4 color4 = Texel(colors, coords);

	vec3 wvert = Texel(wverts, coords).xyz;
	vec3 wnorm = Texel(wnorms, coords).xyz;
	vec3 color = color4.rgb;
	float drawn = color4.a;

	if(drawn == 0.0){
		return vec4(atmoscolor, 1.0);
	}else{
		vec3 lightatmos = hemibrightness(wnorm.y)*atmoscolor;
		vec3 lightpoint = 100.0*pointlightbrightness(pointpos - wvert, wnorm)*pointcolor;

		return vec4((lightatmos + lightpoint)*color, 1.0);
	}
}