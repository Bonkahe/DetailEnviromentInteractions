shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, depth_prepass_alpha;

#include "res://addons/DetailEnviromentInteractions/Shaders/DetailEffectsLibrary.gdshaderinc"

group_uniforms Waves;
uniform float WaveCount = 3.0;
uniform float MaxWaveHeight = 0.2;
uniform float NormalSampleRange = 0.25;

group_uniforms Material;
uniform vec3 SurfaceColor : source_color;
uniform float Roughness : hint_range(0.0, 1.0) = 1.0;
uniform float BaseOpacity : hint_range(0.0, 1.0) = 1.0;

group_uniforms Reflections;
uniform float ReflectionTravel = 1000.0;
uniform float MaxDifference = 10.0;
uniform float ReflectionStepDistance = 1.0;

uniform float ReflectionBottomEdgeFade : hint_range(0.0, 0.5) = 0.157;

uniform vec3 SkyColor : source_color;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;


void vertex() {
	vec4 detailEffectsLayerData = SampleDetailEffectsLayer(NODE_POSITION_WORLD + VERTEX);
	detailEffectsLayerData.b *= detailEffectsLayerData.a;
	float heightrate = sin(detailEffectsLayerData.b * WaveCount);
	float currentHeight = VERTEX.y;
	currentHeight += heightrate * clamp(detailEffectsLayerData.b, 0.0, 1.0) * MaxWaveHeight;
	if (currentHeight != VERTEX.y){
		// generate normals,
		vec3 positionUp = VERTEX + vec3(0.0, 0.0, NormalSampleRange);
		float tempHeight = SampleDetailEffectsLayer(NODE_POSITION_WORLD + positionUp).b * detailEffectsLayerData.a;
		heightrate = sin(tempHeight * WaveCount);
		positionUp.y += heightrate * tempHeight * MaxWaveHeight;

		vec3 positionRight = VERTEX + vec3(NormalSampleRange, 0.0, 0.0);
		tempHeight = SampleDetailEffectsLayer(NODE_POSITION_WORLD + positionRight).b * detailEffectsLayerData.a;
		heightrate = sin(tempHeight * WaveCount);
		positionRight.y += heightrate * tempHeight * MaxWaveHeight;

		vec3 center = vec3(VERTEX.x, currentHeight, VERTEX.z);

		vec3 updir = positionUp - center;
		vec3 rightdir = positionRight - center;
		NORMAL = normalize(cross(updir, rightdir));
		VERTEX = center;
	}

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

void fragment() {

	ROUGHNESS = Roughness;
	ALPHA = BaseOpacity;

	if (FRONT_FACING){
		float screen_depth = texture(depth_texture, SCREEN_UV).x;
		float surface_depth = FRAGCOORD.z;

		vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,screen_depth,1.0);
		world_pos.xyz/=world_pos.w;

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
			if (current_screen_position.y > smoothstep(0.0, 1.0, rd_world.y + 1.0)){
				current_screen_position.y = 0.0;
			}

			depth_texture_probe_raw = texture(depth_texture, current_screen_position).x;
			depth_texture_probe_view_position = get_view_position_from_uv(current_screen_position, depth_texture_probe_raw, INV_PROJECTION_MATRIX);

			depth_diff = depth_texture_probe_view_position.z - current_position_view_space.z;
			//resulting_color = texture(screen_texture, current_screen_position).rgb;

			curBoundaryBlend = boundaryBlend(current_screen_position);
			if (curBoundaryBlend > 0.0){
				resulting_color = texture(screen_texture, current_screen_position).rgb;

				if ( depth_diff >= 0.0 && depth_diff < MaxDifference){
					break;
				}
			}
			//resulting_color = (is_within_screen_boundaries(current_screen_position) && depth_diff >= 0.0 && depth_diff < ssr_max_diff) ? texture(screen_texture, current_screen_position.xy).rgb : vec3(-1.0);
		}
		float blendValue = min(curBoundaryBlend, smoothstep(0.5, 0.6, rd_world.y + 1.0));
		resulting_color = mix(SkyColor, resulting_color, blendValue);


		ALBEDO = resulting_color;
	}
	else{
		ALBEDO = SurfaceColor;
		ALPHA = mix(ALPHA, 1.0, 0.5);
	}
	// Called for every pixel the material is visible on.
}
