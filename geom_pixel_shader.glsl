//love_Canvases[layer]
//VaryingColor		 = vec4 Color
//MainTex			 = Image Texture
//VaryingTexCoord	 = vec2 TexturePosition
//love_PixelCoord	 = vec2 PixelPosition

varying vec4 wvert;
varying vec4 wnorm;

void effect(){
	love_Canvases[0] = vec4(wvert.xyz, 1);
	love_Canvases[1] = vec4(normalize(wnorm.xyz), 1);
	love_Canvases[2] = vec4(VaryingColor.rgb, 1);
}