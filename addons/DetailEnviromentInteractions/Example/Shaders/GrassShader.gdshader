shader_type spatial;
render_mode cull_disabled;

#include "res://addons/DetailEnviromentInteractions/Shaders/DetailEffectsLibrary.gdshaderinc"

uniform float DeformationDirectionSampleRange = 0.5;

uniform sampler2D WindNoise : hint_roughness_r;
uniform float WindNoiseScale = 1.0;
uniform float WindSpeed = 1.0;
uniform float WindScale = 1.0;

uniform sampler2D Albedo : source_color, repeat_disable;
uniform sampler2D NormalMap : hint_normal, repeat_disable;
uniform sampler2D Roughness : hint_roughness_r, repeat_disable;

uniform vec3 baseColor : source_color;
uniform vec3 tampedColor : source_color;

uniform float EffectFadeInSoftness = 1.0;
uniform float EffectMultiplier = 1.0;
uniform float NormalMapPower : hint_range(0.0, 1.0) = 0.5;
uniform float AlphaThreshold : hint_range(0.0001, 1.0) = 0.1;

varying float tampedValue;

void vertex() {
	vec4 detailEffectsLayerData = SampleDetailEffectsLayer(NODE_POSITION_WORLD);

	//vec3 currentpos = VERTEX;
	//currentpos.y = mix(currentpos.y, currentpos.y - 0.5, detailEffectsLayerData.g);
	//VERTEX = currentpos;
	tampedValue = 0.0;
	float effectWeight = smoothstep(EffectFadeInSoftness / 4.0, EffectFadeInSoftness, length(VERTEX));
	if (detailEffectsLayerData.g > 0.0){
		vec3 positionUp =  vec3(0.0, 0.0, DeformationDirectionSampleRange);
		vec4 tempSample = SampleDetailEffectsLayer(NODE_POSITION_WORLD + positionUp);
		positionUp.y += tempSample.g;

		vec3 positionRight =  vec3(DeformationDirectionSampleRange, 0.0, 0.0);
		tempSample = SampleDetailEffectsLayer(NODE_POSITION_WORLD + positionRight);
		positionRight.y += tempSample.g;

		vec3 center = vec3(0.0);
		center.y += detailEffectsLayerData.g;

		vec3 updir = positionUp - center;
		vec3 rightdir = positionRight - center;
		vec3 downwardslope = cross(updir, rightdir);
		downwardslope.y = 0.0;
		downwardslope = normalize(downwardslope);
		tampedValue = clamp(detailEffectsLayerData.g, 0.0, 1.0) * effectWeight;
		VERTEX += mix(downwardslope, vec3(0.0, -1.0, 0.0), 0.5) * tampedValue * EffectMultiplier;
	}

	vec2 currentUV = (NODE_POSITION_WORLD.xz * WindNoiseScale) + (TIME * WindSpeed);
	vec3 windDirection = vec3(0.25, -1.0, 1.0) * texture(WindNoise, currentUV).r;
	vec3 worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	worldPos += windDirection * effectWeight * WindScale * (1.0 - tampedValue);
	VERTEX = (inverse(MODEL_MATRIX) * vec4(worldPos, 1.0)).xyz;
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 albedo = texture(Albedo, UV);
	ALBEDO = albedo.rgb * mix(baseColor, tampedColor, clamp(tampedValue, 0.0, 1.0));
	BACKLIGHT = vec3(1.0);
	ALPHA = albedo.a;
	ALPHA_SCISSOR_THRESHOLD = AlphaThreshold;
	ROUGHNESS = texture(Roughness, UV).r;
	NORMAL_MAP = texture(NormalMap, UV).rgb;
	NORMAL_MAP_DEPTH = NormalMapPower;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
