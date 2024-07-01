shader_type spatial;
render_mode cull_disabled, depth_draw_always, depth_prepass_alpha;

#include "res://addons/DetailEnviromentInteractions/Shaders/DetailEffectsLibrary.gdshaderinc"

group_uniforms Waves;
uniform float WaveCount = 3.0;
uniform float MaxWaveHeight = 0.2;
//uniform float NormalSampleRange = 0.25;

group_uniforms BaseWaves;
uniform float BaseWavesMixSharpness : hint_range(0.0, 1.0) = 0.25;
uniform sampler2D BaseWavesHeightMap;
uniform float BaseWavesHeight;
uniform float BaseWavesScale;
uniform float BaseWavesSpeed;
uniform vec2 BaseWavesDirection;
uniform float BaseWavesNormalSampleRange = 0.25;
uniform float BaseWavesNormalSoftness : hint_range(0.0, 1.0) = 0.25;

group_uniforms Material;
uniform sampler2D SurfaceColor : source_color, repeat_disable;
uniform float Roughness : hint_range(0.0, 1.0) = 1.0;
uniform float BaseOpacity : hint_range(0.0, 1.0) = 1.0;
uniform float EdgeAlphaFade : hint_range(0.0, 100.0) = 1.0;
uniform float EdgeAlphaFadeMinimum : hint_range(0.0, 1.0) = 0.2;


group_uniforms Foam;
uniform sampler2D FoamTexture : hint_roughness_r, repeat_enable;
uniform float FoamScale = 1.0;
uniform float FoamSpeed = 1.0;
uniform float FoamWeight = 1.0;
uniform float FoamShorelineFade : hint_range(0.0, 4096.0, 0.01);
uniform float FoamWavesPower : hint_range(0.0, 5.0) = 1.0;

group_uniforms Reflections;
//uniform bool UseGaussianBlur = false;
//uniform float BlurDirections = 3;
//uniform float BlurQuality = 3;
//uniform float BlurSize = 8.0;

uniform float ReflectionTravel = 1000.0;
uniform float MaxDifference = 10.0;
uniform float ReflectionStepDistance = 1.0;

uniform float ReflectionBottomEdgeFade : hint_range(0.0, 0.5) = 0.157;
uniform vec3 ReflectionTint : source_color;
uniform vec3 SkyColor : source_color;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

varying float foamWeight;


void vertex() {
	vec4 detailEffectsLayerData = SampleDetailEffectsLayer(NODE_POSITION_WORLD + VERTEX);
	detailEffectsLayerData.b *= detailEffectsLayerData.a;

	float dynamicHeightBlend = smoothstep(0.0, BaseWavesMixSharpness, detailEffectsLayerData.b);
	vec3 BaseCenter = (NODE_POSITION_WORLD + VERTEX).xyz * vec3(BaseWavesScale, 1.0, BaseWavesScale);
	//(BaseUV * BaseWavesScale) +
	vec2 BaseWavesUVAdjustment = (normalize(BaseWavesDirection) * TIME * BaseWavesSpeed);

	float originalY = VERTEX.y;

	//vec3 newNormals = (texture(BaseWavesNormalMap, BaseWavesUV).rgb * 2.0) - vec3(1.0);
	//newNormals.z *= -1.0;
	//NORMAL = inverse(MODEL_NORMAL_MATRIX) * texture(BaseWavesNormalMap, BaseWavesUV).rgb;
	vec3 baseWavesUp = BaseCenter + vec3(0.0, 0.0, BaseWavesNormalSampleRange);
	baseWavesUp.y += texture(BaseWavesHeightMap, baseWavesUp.xz + BaseWavesUVAdjustment).r * BaseWavesHeight;;

	vec3 baseWavesRight = BaseCenter + vec3(BaseWavesNormalSampleRange, 0.0, 0.0);
	baseWavesRight.y += texture(BaseWavesHeightMap, baseWavesRight.xz + BaseWavesUVAdjustment).r * BaseWavesHeight;;

	float centerHeight = texture(BaseWavesHeightMap, BaseCenter.xz + BaseWavesUVAdjustment).r * BaseWavesHeight;
	BaseCenter.y += centerHeight;

	vec3 baseupdir = baseWavesUp - BaseCenter;
	vec3 baserightdir = baseWavesRight - BaseCenter;
	NORMAL = mix(normalize(cross(baseupdir, baserightdir)), NORMAL, BaseWavesNormalSoftness);
	VERTEX.y += mix(centerHeight, 0.0, dynamicHeightBlend * 0.2);

	float currentHeight = VERTEX.y;
	currentHeight += detailEffectsLayerData.b * clamp(detailEffectsLayerData.b, 0.0, 1.0) * MaxWaveHeight;
	if (currentHeight != VERTEX.y){
		vec4 normalandHeight = RetrieveNormalMapAndHeight(NODE_POSITION_WORLD + VERTEX, 2);
		NORMAL = mix(NORMAL, normalandHeight.xyz, dynamicHeightBlend);
		VERTEX = vec3(VERTEX.x, max(VERTEX.y, VERTEX.y + normalandHeight.a), VERTEX.z);
		//
		//// generate normals,
		//vec3 positionUp = VERTEX + vec3(0.0, 0.0, NormalSampleRange);
		//float tempHeight = SampleDetailEffectsLayer(NODE_POSITION_WORLD + positionUp).b * detailEffectsLayerData.a;
//
		//positionUp.y += tempHeight * MaxWaveHeight;
//
		//vec3 positionRight = VERTEX + vec3(NormalSampleRange, 0.0, 0.0);
		//tempHeight = SampleDetailEffectsLayer(NODE_POSITION_WORLD + positionRight).b * detailEffectsLayerData.a;
//
		//positionRight.y += tempHeight * MaxWaveHeight;
//
		//vec3 center = vec3(VERTEX.x, max(VERTEX.y, currentHeight), VERTEX.z);
//
		//vec3 updir = positionUp - center;
		//vec3 rightdir = positionRight - center;
		//NORMAL = mix(NORMAL, normalize(cross(updir, rightdir)), dynamicHeightBlend);
		//VERTEX = center;
	}
	foamWeight = pow(max(abs( VERTEX.y - originalY), dynamicHeightBlend / 3.0), 3.0);
	// Called for every vertex the material is visible on.
}



// Reflections
float boundaryBlend(vec2 position){
	float bottomBoundry = smoothstep(0.0, ReflectionBottomEdgeFade, clamp(position.y, 0.0, 1.0));
	return bottomBoundry;
}

bool is_within_screen_boundaries(vec2 position) {
	return position.x > 0.0 && position.x < 1.0 && position.y > 0.0 && position.y < 1.0;
}

vec2 get_uv_from_view_position(vec3 position_view_space, mat4 proj_m)
{
	vec4 position_clip_space = proj_m * vec4(position_view_space.xyz, 1.0);
	vec2 position_ndc = position_clip_space.xy / position_clip_space.w;
	return position_ndc.xy * 0.5 + 0.5;
}

vec3 get_view_position_from_uv(vec2 uv, float depth, mat4 inv_proj_m)
{
	vec4 position_ndc = vec4((uv * 2.0) - 1.0, depth, 1.0);
	vec4 view_position = inv_proj_m * position_ndc;
	return view_position.xyz /= view_position.w;
}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}
//
//vec3 RetrieveGaussianValue(vec2 currentUV, float lastHeight){
    //
	//// GAUSSIAN BLUR SETTINGS {{{
	//// GAUSSIAN BLUR SETTINGS }}}
	//
	//vec2 Radius = BlurSize / vec2(textureSize(screen_texture, 0));
	//
	//// Pixel colour
	//vec4 Color = texture(screen_texture, currentUV);
//
	//// Blur calculations
	//for( float d=0.0; d<PI; d+=PI/BlurDirections)
	//{
		//for(float i=1.0/BlurQuality; i<=1.0; i+=1.0/BlurQuality)
	    //{
			//Color += texture( screen_texture, currentUV + vec2( cos(d), sin(d)) * Radius * i);
	    //}
	//}
//
	//// Output to screen
	//Color /= BlurQuality * BlurDirections;
	//
	//return Color.rgb;
//}

void fragment() {
	
	ROUGHNESS = Roughness;
	ALPHA = BaseOpacity;
	float screen_depth = texture(depth_texture, SCREEN_UV).x;
	float surface_depth = FRAGCOORD.z;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,screen_depth,1.0);
	world_pos.xyz/=world_pos.w;
	
	
	
	if (FRONT_FACING){
		
		
		vec3 screen_view_position = get_view_position_from_uv(SCREEN_UV, screen_depth, INV_PROJECTION_MATRIX);
		vec3 surface_view_position = get_view_position_from_uv(SCREEN_UV, surface_depth, INV_PROJECTION_MATRIX);

		//float distanceBlend = clamp(length(surface_view_position) / MaxReflectionDistanceScale, 0.0, 1.0);
		vec3 current_position_view_space = surface_view_position;
		vec3 view_direction_view_space = VIEW * -1.0;
		vec3 reflect_vector_view_space = normalize(reflect(view_direction_view_space.xyz, NORMAL.xyz));

		vec2 current_screen_position = vec2(0.0);
		vec3 resulting_color = SkyColor;
		float curBoundaryBlend = 0.0;
		float currentMaxTravel = ReflectionTravel;
		//float currentMaxTravel = mix(ReflectionMinTravel, ReflectionMaxTravel, distanceBlend);
		float lowest_depth_diff = currentMaxTravel;
		float finalTravel = 0.0;
		float ssrCurResolution = ReflectionStepDistance;
		//float ssrCurResolution = max(mix(MinReflectionStepDistance, MaxReflectionStepDistance, distanceBlend), 1.0);

		vec4 clipPos = vec4((FRAGCOORD.xy / VIEWPORT_SIZE.xy) * 2.0 - 1.0, FRAGCOORD.z, 1.0);
		vec4 viewPos = INV_PROJECTION_MATRIX * clipPos;
		vec3 rd_world = normalize(viewPos.xyz / viewPos.w);
		rd_world = mat3(INV_VIEW_MATRIX) * rd_world;

		vec3 depth_texture_probe_view_position = vec3(0.0);
		float depth_texture_probe_raw = 0.0;
		float depth_diff = 0.0;
		float roughnessControl = 0.0;
		for(float travel=0.0;  travel < currentMaxTravel; travel = travel + ssrCurResolution)
		{
			finalTravel = travel;
			current_position_view_space += reflect_vector_view_space * ssrCurResolution;
			current_screen_position = get_uv_from_view_position(current_position_view_space, PROJECTION_MATRIX);
			//if (current_screen_position.y > smoothstep(0.0, 1.0, rd_world.y + 1.0)){
				//current_screen_position.y = 0.0;
			//}

			depth_texture_probe_raw = texture(depth_texture, current_screen_position).x;
			depth_texture_probe_view_position = get_view_position_from_uv(current_screen_position, depth_texture_probe_raw, INV_PROJECTION_MATRIX);

			depth_diff = depth_texture_probe_view_position.z - (MaxDifference / 2.0) - current_position_view_space.z;
			//resulting_color = texture(screen_texture, current_screen_position).rgb;

			curBoundaryBlend = boundaryBlend(current_screen_position);
			if (curBoundaryBlend > 0.0){
				//if (depth_texture_probe_view_position.z > currentMaxTravel * -1.0){
					//resulting_color = texture(screen_texture, current_screen_position).rgb;
				//}
				if ( depth_diff >= 0.0 && depth_diff < MaxDifference){
					resulting_color = texture(screen_texture, current_screen_position).rgb;
					//if (UseGaussianBlur){
						//resulting_color = RetrieveGaussianValue(current_screen_position, current_position_view_space.z);
					//}
					//else{
						//resulting_color = texture(screen_texture, current_screen_position).rgb;
					//}
					break;
				}
			}
			if (depth_texture_probe_view_position.z < current_position_view_space.z && travel + ssrCurResolution >= currentMaxTravel){
				//if (UseGaussianBlur){
					//resulting_color = RetrieveGaussianValue(current_screen_position, current_position_view_space.z);
				//}
				//else{
					//resulting_color = texture(screen_texture, current_screen_position).rgb;
				//}
				resulting_color = texture(screen_texture, current_screen_position).rgb;
			}
			//resulting_color = (is_within_screen_boundaries(current_screen_position) && depth_diff >= 0.0 && depth_diff < ssr_max_diff) ? texture(screen_texture, current_screen_position.xy).rgb : vec3(-1.0);
		}
		float blendValue = min(curBoundaryBlend, smoothstep(0.5, 0.6, rd_world.y + 1.0));
		resulting_color = mix(SkyColor, resulting_color * ReflectionTint, blendValue);
		
		ALBEDO = (resulting_color * (1.0 - foamWeight)) + texture(SurfaceColor, vec2(clamp(smoothstep(world_pos.z + 10.0, world_pos.z, VERTEX.z), 0.0, 1.0), 0.5)).rgb;
		//ALBEDO = resulting_color;
	}
	else{
		ALBEDO = texture(SurfaceColor, vec2(0.5, foamWeight)).rgb;
		BACKLIGHT = ALBEDO;
		ALPHA = mix(ALPHA, 1.0, 0.9);
	}
	
	float wavesFoamWeight = pow(foamWeight  * FoamWeight, FoamWavesPower);
	wavesFoamWeight += clamp(smoothstep(world_pos.z + FoamShorelineFade, world_pos.z, VERTEX.z), 0.0, 1.0);
	//wavesFoamWeight = clamp(wavesFoamWeight, 0.0, 1.0);
	vec2 foamPos = ((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz * FoamScale);
	vec2 foamUV = foamPos + (normalize(BaseWavesDirection * -1.0) * TIME * FoamSpeed);
	vec3 foamTexureA = texture(FoamTexture, foamPos + (normalize(BaseWavesDirection * -1.0) * TIME * FoamSpeed)).rgb;
	vec3 foamTexureB = texture(FoamTexture, foamPos + (normalize(BaseWavesDirection * -0.5 + vec2(0.1, 0.3)) * TIME * FoamSpeed)).rgb;
	wavesFoamWeight = max(foamTexureA.r, foamTexureB.r) * wavesFoamWeight;
	
	
	//ALPHA = 1.0;
	//ALPHA = clamp(ALPHA + wavesFoamWeight, 0.0, 1.0);
	ALPHA = mix(ALPHA, EdgeAlphaFadeMinimum, clamp(smoothstep(world_pos.z + EdgeAlphaFade, world_pos.z, VERTEX.z), 0.0, 1.0));
	//ALBEDO += vec3(clamp(wavesFoamWeight, 0.0, 1.0));
	ALBEDO = mix(ALBEDO, max(foamTexureA, foamTexureB), clamp(wavesFoamWeight, 0.0, 1.0));
	
	//wavesFoamWeight +=
	//ALBEDO = texture(FoamTexture, foamUV).rgb;
	//ALPHA = wavesFoamWeight;
	//ALBEDO = vec3(smoothstep(world_pos.z + 0.3, world_pos.z + 0.1, VERTEX.z));
	//ALBEDO = vec3(clamp(wavesFoamWeight, 0.0, 1.0));
}
