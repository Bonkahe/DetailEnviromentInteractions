shader_type spatial;

global uniform sampler2D GrassDetailViewportTexture;
global uniform float GrassDetailViewportTextureSize;
global uniform vec3 GrassDetailViewportTextureCornerPosition;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = texture(GrassDetailViewportTexture, UV).rgb;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
