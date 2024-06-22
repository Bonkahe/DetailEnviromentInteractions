shader_type spatial;

#include "res://addons/DetailEnviromentInteractions/Shaders/DetailEffectsLibrary.gdshaderinc"

uniform float TextureUVScale = 0.5;
uniform float TextureBlendSoftness : hint_range(0.0, 1.0) = 0.1;

uniform float SnowDisplacementRangeUpper = 0.1;
uniform float SnowDisplacementRangeLower = 0.05;
uniform float SnowBlendingColorRange = 0.1;
uniform float SnowBlendingNoiseUVScale = 0.1;
uniform sampler2D SnowBlendingNoise : hint_roughness_r;
uniform float SnowBaseHeight;

#ifdef USE_DISPLACEMENT
uniform float MaxMudDisplacement = 0.2;
#endif

uniform vec3 FootprintColor : source_color;

uniform sampler2D MudAlbedo : source_color;
uniform sampler2D MudNormalMap : hint_normal;
uniform sampler2D MudHeightMap : hint_roughness_r;
uniform sampler2D MudRoughnessMap : hint_roughness_r;
uniform float MudRoughnessPower : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D GrassAlbedo : source_color;
uniform sampler2D GrassNormalMap : hint_normal;
uniform sampler2D GrassHeightMap : hint_roughness_r;
uniform sampler2D GrassRoughnessMap : hint_roughness_r;
uniform float GrassRoughnessPower : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D SnowAlbedo : source_color;
uniform sampler2D SnowNormalMap : hint_normal;
uniform sampler2D SnowHeightMap : hint_roughness_r;
uniform sampler2D SnowRoughnessMap : hint_roughness_r;
uniform float SnowRoughnessPower : hint_range(0.0, 1.0) = 1.0;


varying float currentSnowHeight;
#ifdef USE_DISPLACEMENT
void vertex() {
	vec2 currentSnowNoiseUV = VERTEX.xz * SnowBlendingNoiseUVScale;
	float currentSnowNoiseWeight = texture(SnowBlendingNoise, currentSnowNoiseUV).r;

	vec4 detailEffectsLayerData = SampleDetailEffectsLayer(NODE_POSITION_WORLD + VERTEX);
	detailEffectsLayerData.r = clamp(detailEffectsLayerData.r, 0.0, 1.0);
	currentSnowHeight = (COLOR.g - COLOR.r) * SnowBaseHeight * (1.0 - detailEffectsLayerData.r); //subtract footsteps later
	currentSnowHeight = pow(currentSnowHeight, currentSnowNoiseWeight);

	float currentY = VERTEX.y;
	float adjustedHeight = smoothstep(SnowDisplacementRangeLower, SnowDisplacementRangeUpper, currentSnowHeight);
	adjustedHeight = max(adjustedHeight, 0.0);
	currentY += SnowBaseHeight * adjustedHeight;
	currentY -= MaxMudDisplacement * detailEffectsLayerData.r * (1.0 - COLOR.r);
	VERTEX.y = currentY;
	// Called for every vertex the material is visible on.
}
#endif

float HeightBasedFloatMix(float colorA, float colorB, float heightA, float heightB, float lerpvalue){

	heightA += 1.0 - lerpvalue;
	heightB += lerpvalue;

	float blendValue = max(heightA, heightB) - TextureBlendSoftness;

	heightA -= blendValue;
	heightB -= blendValue;

	heightA = max(heightA, 0.0);
	heightB = max(heightB, 0.0);

	colorA *= heightA;
	colorB *= heightB;

	return (colorA + colorB) / (heightA + heightB);
}

vec3 HeightBasedVec3Mix(vec3 colorA, vec3 colorB, float heightA, float heightB, float lerpvalue){
	heightA += 1.0 - lerpvalue;
	heightB += lerpvalue;

	float blendValue = max(heightA, heightB) - TextureBlendSoftness;

	heightA -= blendValue;
	heightB -= blendValue;

	heightA = max(heightA, 0.0);
	heightB = max(heightB, 0.0);

	colorA *= heightA;
	colorB *= heightB;

	return (colorA + colorB) / (heightA + heightB);
}

void fragment() {
	vec3 CurrentColor = vec3(0.0);
	vec3 CurrentNormalMap = vec3(0.0);
	float CurrentRoughness = 0.0;
	#ifdef USE_DISPLACEMENT
	vec3 worldposition = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 worldUV = worldposition.xz * TextureUVScale;
	vec4 detailEffectsLayerData = SampleDetailEffectsLayer(worldposition);
	detailEffectsLayerData.r = clamp(detailEffectsLayerData.r, 0.0, 1.0);
	float grassHeight = texture(GrassHeightMap, worldUV).r;
	float mudHeight = texture(GrassHeightMap, worldUV).r;
	float snowHeight = texture(GrassHeightMap, worldUV).r;

	float grassWeight = COLOR.r;
	CurrentColor = texture(MudAlbedo, worldUV).rgb * mix(vec3(1.0), FootprintColor, detailEffectsLayerData.r);
	CurrentNormalMap = texture(MudNormalMap, worldUV).rgb;
	CurrentRoughness = texture(MudRoughnessMap, worldUV).r * MudRoughnessPower;

	CurrentRoughness = mix(CurrentRoughness, pow(CurrentRoughness, 2.0), detailEffectsLayerData.r);
	CurrentColor = HeightBasedVec3Mix(CurrentColor, texture(GrassAlbedo, worldUV).rgb, mudHeight, grassHeight, grassWeight);
	CurrentNormalMap = HeightBasedVec3Mix(CurrentNormalMap, texture(GrassNormalMap, worldUV).rgb, mudHeight, grassHeight, grassWeight);
	CurrentRoughness = HeightBasedFloatMix(CurrentRoughness, texture(GrassRoughnessMap, worldUV).r * GrassRoughnessPower, mudHeight, grassHeight, grassWeight);

	float currentTextureHeight = max(mudHeight, grassHeight);

	float currentSnowWeight = smoothstep(0.0, SnowBlendingColorRange, currentSnowHeight);
	CurrentColor = HeightBasedVec3Mix(CurrentColor,texture(SnowAlbedo, worldUV).rgb * mix(vec3(1.0), FootprintColor, detailEffectsLayerData.r * (1.0 - grassWeight)), currentTextureHeight, snowHeight, currentSnowWeight);
	CurrentNormalMap = HeightBasedVec3Mix(CurrentNormalMap, texture(SnowNormalMap, worldUV).rgb, currentTextureHeight, snowHeight, currentSnowWeight);
	CurrentRoughness = HeightBasedFloatMix(CurrentRoughness, texture(SnowRoughnessMap, worldUV).r * SnowRoughnessPower, currentTextureHeight, snowHeight, currentSnowWeight);

	#else
	vec3 worldposition = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 worldUV = worldposition.xz * TextureUVScale;
	vec4 detailEffectsLayerData = SampleDetailEffectsLayer(worldposition);
	detailEffectsLayerData.r = clamp(detailEffectsLayerData.r, 0.0, 1.0);

	vec2 currentSnowNoiseUV = worldposition.xz * SnowBlendingNoiseUVScale;
	float currentSnowNoiseWeight = texture(SnowBlendingNoise, currentSnowNoiseUV).r;

	currentSnowHeight = (COLOR.g - COLOR.r) * SnowBaseHeight * (1.0 - detailEffectsLayerData.r);
	currentSnowHeight = pow(currentSnowHeight, currentSnowNoiseWeight);

	#ifdef USE_PARALAX
	worldUV = SampleDetailEffectsLayerParallax(worldposition, VERTEX, TANGENT, BINORMAL, NORMAL);
	#endif

	float grassHeight = texture(GrassHeightMap, worldUV).r;
	float mudHeight = texture(GrassHeightMap, worldUV).r;
	float snowHeight = texture(GrassHeightMap, worldUV).r;

	float grassWeight = COLOR.r;
	CurrentColor = texture(MudAlbedo, worldUV).rgb * mix(vec3(1.0), FootprintColor, detailEffectsLayerData.r);
	CurrentNormalMap = texture(MudNormalMap, worldUV).rgb;
	CurrentRoughness = texture(MudRoughnessMap, worldUV).r * MudRoughnessPower;

	CurrentRoughness = mix(CurrentRoughness, pow(CurrentRoughness, 2.0), detailEffectsLayerData.r);
	CurrentColor = HeightBasedVec3Mix(CurrentColor, texture(GrassAlbedo, worldUV).rgb, mudHeight, grassHeight, grassWeight);
	CurrentNormalMap = HeightBasedVec3Mix(CurrentNormalMap, texture(GrassNormalMap, worldUV).rgb, mudHeight, grassHeight, grassWeight);
	CurrentRoughness = HeightBasedFloatMix(CurrentRoughness, texture(GrassRoughnessMap, worldUV).r * GrassRoughnessPower, mudHeight, grassHeight, grassWeight);

	float currentTextureHeight = max(mudHeight, grassHeight);

	float currentSnowWeight = smoothstep(0.0, SnowBlendingColorRange, currentSnowHeight);
	CurrentColor = HeightBasedVec3Mix(CurrentColor,texture(SnowAlbedo, worldUV).rgb * mix(vec3(1.0), FootprintColor, detailEffectsLayerData.r * (1.0 - grassWeight)), currentTextureHeight, snowHeight, currentSnowWeight);
	CurrentNormalMap = HeightBasedVec3Mix(CurrentNormalMap, texture(SnowNormalMap, worldUV).rgb, currentTextureHeight, snowHeight, currentSnowWeight);
	CurrentRoughness = HeightBasedFloatMix(CurrentRoughness, texture(SnowRoughnessMap, worldUV).r * SnowRoughnessPower, currentTextureHeight, snowHeight, currentSnowWeight);

	#endif
	ALBEDO = CurrentColor;
	NORMAL_MAP = CurrentNormalMap;
	ROUGHNESS = CurrentRoughness;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
