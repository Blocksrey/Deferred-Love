//attributes are sent in
//norm is the normal of the vertex
attribute vec4 norm;

//uniforms are sent in by the user using shader:send(name, value)
//frusT transforms vertices in the camera frustum to a box (-1, -1, -1) to (1, 1, 1)
//vertT transforms a vertex from identity space to world space
//normT transforms a normal from identity space to world space
uniform mat4 frusT;
uniform mat4 vertT;
uniform mat4 normT;

//varyings are used by the effect shader
//these will show up in the pixel shader,
//linerally interpolated by GLSL depending
//on the position of the pixel on the triangle
//wvert is the world space vertex
//wnorm is the world space normal
varying vec4 wvert;
varying vec4 wnorm;
//varying float depth;

//We do not use the given transformation matrix (1st arg) because we cannot define it
vec4 position(mat4 I, vec4 vert){
	//Transform the vert info to world space
	wvert = vertT*vert;
	wnorm = vec4(normalize((normT*norm).xyz), 1.0);

	//Convert the world space vertex into (almost) frustum coords
	vec4 fvert = frusT*wvert;

	//depth = fvert.w;

	return fvert;
}