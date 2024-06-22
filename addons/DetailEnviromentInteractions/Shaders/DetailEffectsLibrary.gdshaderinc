
#define USE_DISPLACEMENT
//#define USE_PARALAX

#ifdef USE_PARALAX
uniform float heightmap_scale : hint_range(-16.0, 16.0, 0.001);
uniform int heightmap_min_layers : hint_range(1, 64);
uniform int heightmap_max_layers : hint_range(1, 64);
#endif

global uniform sampler2D GrassDetailViewportTexture;
global uniform float GrassDetailViewportTextureSize; //Full diameter of the detail effects render area
global uniform vec3 GrassDetailViewportTextureCornerPosition;

uniform bool FadeEffectAtEdges;
uniform float EdgeFadeSmoothness;

vec4 SampleDetailEffectsLayer(vec3 worldPosition){

	vec3 delta = worldPosition - GrassDetailViewportTextureCornerPosition;
	vec2 uv = delta.xz / GrassDetailViewportTextureSize;
	if (uv != clamp(uv, 0.0, 1.0)){
		return vec4(0.0);
	}

	uv = clamp(uv, 0.0, 1.0);
	if (FadeEffectAtEdges){
		vec2 worldPosBase = worldPosition.xz;
		vec2 textureWorldPosition = GrassDetailViewportTextureCornerPosition.xz + vec2(GrassDetailViewportTextureSize / 2.0);
		float edgeFade = length(worldPosBase - textureWorldPosition);
		edgeFade = smoothstep(GrassDetailViewportTextureSize / 2.0, (GrassDetailViewportTextureSize / 2.0) - EdgeFadeSmoothness, edgeFade);
		return vec4(texture(GrassDetailViewportTexture, uv).rgb, edgeFade);
	}
	else{
		return texture(GrassDetailViewportTexture, uv);
	}
}

#ifdef USE_PARALAX
vec2 SampleDetailEffectsLayerParallax(vec3 worldPosition, vec3 Vertex, vec3 Tangent, vec3 Binormal, vec3 Normal){

	vec3 delta = worldPosition - GrassDetailViewportTextureCornerPosition;
	vec2 uv = delta.xz / GrassDetailViewportTextureSize;
	if (uv != clamp(uv, 0.0, 1.0)){
		return worldPosition.xz;
	}

	uv = clamp(uv, 0.0, 1.0);


	{
		// Height: Enabled
		vec3 view_dir = normalize(normalize(-Vertex) * mat3(Tangent, -Binormal, Normal));

		// Height Deep Parallax: Enabled
		float num_layers = mix(float(heightmap_max_layers), float(heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
		float layer_depth = 1.0 / num_layers;
		float current_layer_depth = 0.0;
		vec2 p = view_dir.xy * heightmap_scale * 0.01;
		vec2 delta = p / num_layers;
		vec2 ofs = uv;
		vec2 ofsworldPos = worldPosition.xz;
		float depth = 1.0 - texture(GrassDetailViewportTexture, ofs).r;

		float current_depth = 0.0;
		while (current_depth < depth) {
			ofs -= delta;
			ofsworldPos -= delta;
			depth = 1.0 - texture(GrassDetailViewportTexture, ofs).r;

			current_depth += layer_depth;
		}

		vec2 prev_ofs = ofs + delta;
		vec2 prev_ofsworldpos = ofsworldPos + delta;
		float after_depth = depth - current_depth;
		float before_depth = (1.0 - texture(GrassDetailViewportTexture, prev_ofs).r) - current_depth + layer_depth;

		float weight = after_depth / (after_depth - before_depth);
		//ofs = mix(ofs, prev_ofs, weight);
		ofsworldPos = mix(ofsworldPos, prev_ofsworldpos, weight);
		uv = ofsworldPos;
	}

	if (FadeEffectAtEdges){
		vec2 worldPosBase = worldPosition.xz;
		vec2 textureWorldPosition = GrassDetailViewportTextureCornerPosition.xz + vec2(GrassDetailViewportTextureSize / 2.0);
		float edgeFade = length(worldPosBase - textureWorldPosition);
		edgeFade = smoothstep(GrassDetailViewportTextureSize / 2.0, (GrassDetailViewportTextureSize / 2.0) - EdgeFadeSmoothness, edgeFade);
		return mix(worldPosition.xz, uv, edgeFade );
	}
	else{
		return uv;
	}
}
#endif