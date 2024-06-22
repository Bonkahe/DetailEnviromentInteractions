shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled, blend_add;

uniform sampler2D StampAlpha : hint_roughness_r, repeat_disable;
instance uniform float ParticleOpacity : hint_range(0.0, 1.0) = 1.0;
uniform int EffectChannel : hint_range(0, 2, 1);
uniform float EffectWeight : hint_range(0.0, 1.0) = 1.0;


void fragment() {
	vec3 color = vec3(0.0);
	color[EffectChannel] = texture(StampAlpha, UV).r * ParticleOpacity * EffectWeight;
	ALBEDO = color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
