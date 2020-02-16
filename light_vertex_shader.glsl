//love_Canvases[layer]
//VaryingColor		 = vec4 Color
//MainTex			 = Image Texture
//VaryingTexCoord	 = vec2 TexturePosition
//love_PixelCoord	 = vec2 PixelPosition

uniform mat4 frusT;
uniform mat4 vertT;

vec4 position(mat4 I, vec4 vert){
	return frusT*vertT*vert;
}