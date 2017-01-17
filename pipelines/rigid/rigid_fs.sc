#if defined BUMP_TEXTURE && !defined SKINNED
	$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2, v_tangent_view_pos
#else
	$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2
#endif	
	
#include "common.sh"

#ifdef DIFFUSE_TEXTURE
	SAMPLER2D(u_texColor, 0);
#endif
#ifdef NORMAL_MAPPING
	SAMPLER2D(u_texNormal, 1);
#endif
#ifdef ROUGHNESS_TEXTURE
	SAMPLER2D(u_texRoughness, 2);
#endif
#ifdef METALLIC_TEXTURE
	SAMPLER2D(u_texMetallic, 3);
#endif
#ifdef BUMP_TEXTURE
	SAMPLER2D(u_texBump, 4);
#endif
#ifdef AMBIENT_OCCLUSION
	SAMPLER2D(u_texAO, 5);
#endif
uniform vec4 u_materialColor;
uniform vec4 u_roughnessMetallic;
uniform vec4 u_parallaxScale;


#ifdef BUMP_TEXTURE
vec2 parallaxMapping(sampler2D bump_map, vec2 tex_coords, vec3 view_dir)
{ 
	float height_scale = u_parallaxScale.x;
    const float MIN_LAYERS = 10;
    const float MAX_LAYERS = 20;
    float num_layers = mix(MAX_LAYERS, MIN_LAYERS, abs(view_dir.y));  
    float layer_depth = 1.0 / num_layers;
    float current_layer_depth = 0.0;
    vec2 P = view_dir.xz * height_scale; 
    vec2 delta_tex_coords = P / num_layers;
  
    vec2  current_tex_coords     = tex_coords;
    float current_depthmap_value = texture2D(bump_map, current_tex_coords).r;
      
	#if BGFX_SHADER_LANGUAGE_HLSL
	[unroll(20)]
	#endif
    while(current_layer_depth < current_depthmap_value)
    {
        current_tex_coords += delta_tex_coords;
        current_depthmap_value = texture2D(bump_map, current_tex_coords).r;  
        current_layer_depth += layer_depth;  
    }

    vec2 prev_tex_coords = current_tex_coords - delta_tex_coords;

    float after_depth  = current_depthmap_value - current_layer_depth;
    float before_depth = texture2D(bump_map, prev_tex_coords).r - current_layer_depth + layer_depth;
	float depth_diff = after_depth - before_depth;
	if(abs(depth_diff) < 0.0001) depth_diff = 0.0001;
 
    float weight = clamp(after_depth / depth_diff, 0, 1);
    return prev_tex_coords * weight + current_tex_coords * (1.0 - weight);
}

#endif


void main()
{     
	#ifdef BUMP_TEXTURE
		vec2 tex_coords = parallaxMapping(u_texBump, v_texcoord0, normalize(-v_tangent_view_pos));
	#else
		vec2 tex_coords = v_texcoord0;
	#endif

	#ifdef DIFFUSE_TEXTURE
		vec4 color = texture2D(u_texColor, tex_coords);
		#ifdef ALPHA_CUTOUT
			if(color.a < u_alphaRef) discard;
		#endif
	#else
		vec4 color = vec4(1, 1, 1, 1);
	#endif
	color.xyz *= u_materialColor.rgb;
	#ifdef SHADOW
		float depth = v_common2.z / v_common2.w;
		gl_FragColor = vec4_splat(depth);
	#else
		#ifdef ROUGHNESS_TEXTURE
			float roughness = texture2D(u_texRoughness, tex_coords).x * u_roughnessMetallic.x;
		#else
			float roughness = u_roughnessMetallic.x;
		#endif
		#ifdef METALLIC_TEXTURE
			float metallic = texture2D(u_texMetallic, tex_coords).x * u_roughnessMetallic.y;
		#else
			float metallic = u_roughnessMetallic.y;
		#endif
	
		gl_FragData[0] = vec4(color.rgb, roughness);
		vec3 normal;
		#ifdef NORMAL_MAPPING
			mat3 tbn = mat3(
				normalize(v_tangent),
				normalize(v_normal),
				normalize(v_bitangent)
				);
			tbn = transpose(tbn);
			
			normal.xz = texture2D(u_texNormal, tex_coords).xy * 2.0 - 1.0;
			normal.y = sqrt(clamp(1 - dot(normal.xz, normal.xz), 0, 1)); 
			normal = normalize(mul(tbn, normal));
		#else
			normal = normalize(v_normal);
		#endif
		gl_FragData[1].xyz = (normal + 1) * 0.5; // todo: store only xz 
		gl_FragData[1].w = metallic;
		#ifdef AMBIENT_OCCLUSION
			gl_FragData[2] = vec4(texture2D(u_texAO, tex_coords).x, 0, 0, 1);
		#else
			gl_FragData[2] = vec4(1, 0, 0, 1);
		#endif
	#endif
}
