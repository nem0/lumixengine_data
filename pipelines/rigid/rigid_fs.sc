#if defined BUMP_TEXTURE && !defined SKINNED
	$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2, v_tangent_view_pos
#else
	$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2
#endif	
	
#include "common.sh"

SAMPLER2D(u_texColor, 0);
SAMPLER2D(u_texNormal, 1);
SAMPLER2D(u_texRoughness, 2);
SAMPLER2D(u_texMetallic, 3);
#ifdef BUMP_TEXTURE
	SAMPLER2D(u_texBump, 4);
#endif
#ifdef AMBIENT_OCCLUSION
	SAMPLER2D(u_texAO, 5);
#endif
#ifdef FORWARD
	SAMPLERCUBE(u_irradiance_map, 15);
	SAMPLERCUBE(u_radiance_map, 14);
	SAMPLER2D(u_texShadowmap, 13);
#endif
uniform vec4 u_materialColor;
uniform vec4 u_roughnessMetallicEmission;
uniform vec4 u_parallaxScale;

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbAndIndirectIntensity;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_attenuationParams;
uniform vec4 u_fogParams;


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

vec3 toLinear(vec3 _rgb)
{
	return pow(abs(_rgb), vec3_splat(2.2) );
}

vec4 toLinear(vec4 _rgba)
{
	return vec4(toLinear(_rgba.xyz), _rgba.w);
}

void main()
{     
	#ifdef BUMP_TEXTURE
		vec2 tex_coords = parallaxMapping(u_texBump, v_texcoord0, normalize(-v_tangent_view_pos));
	#else
		vec2 tex_coords = v_texcoord0;
	#endif

	vec4 color = toLinear(u_materialColor.rgba);
	color *= texture2D(u_texColor, tex_coords);
	#ifdef ALPHA_CUTOUT
		if(color.a < u_alphaRef) discard;
	#endif
	#ifdef SHADOW
		float depth = v_common2.z / v_common2.w;
		gl_FragColor = vec4_splat(depth);
	#else
		#ifdef DEFERRED
			float roughness = texture2D(u_texRoughness, tex_coords).x * u_roughnessMetallicEmission.x;
			float metallic = texture2D(u_texMetallic, tex_coords).x * u_roughnessMetallicEmission.y;
			float emission = u_roughnessMetallicEmission.z;
		
			gl_FragData[0] = vec4(color.rgb, roughness);
			vec3 normal;
			mat3 tbn = mat3(
				normalize(v_tangent),
				normalize(v_normal),
				normalize(v_bitangent)
				);
			
			normal.xz = texture2D(u_texNormal, tex_coords).xy * 2.0 - 1.0;
			normal.y = sqrt(clamp(1 - dot(normal.xz, normal.xz), 0, 1)); 
			normal = normalize(mul(normal, tbn));
			gl_FragData[1].xyz = normal * 0.5 + 0.5; // todo: store only xz 
			gl_FragData[1].w = metallic;
			float packed_emission = packEmission(emission);
			#ifdef AMBIENT_OCCLUSION
				gl_FragData[2] = vec4(texture2D(u_texAO, tex_coords).x, packed_emission, 0, 1);
			#else
				gl_FragData[2] = vec4(1, packed_emission, 0, 1);
			#endif
		#else // DEFERRED
			mat3 tbn = mat3(
				normalize(v_tangent),
				normalize(v_normal),
				normalize(v_bitangent)
			);
						
			vec3 wnormal;
			wnormal.xz = texture2D(u_texNormal, v_texcoord0).xy * 2.0 - 1.0;
			wnormal.y = sqrt(1.0 - dot(wnormal.xz, wnormal.xz) );
			wnormal = mul(wnormal, tbn);
			
			float f0 = 0.04;
			
			vec3 normal = wnormal;
			vec4 albedo = color;
			float roughness = u_roughnessMetallicEmission.x;
			float metallic = u_roughnessMetallicEmission.y;
			float emission = u_roughnessMetallicEmission.z;
			
			vec4 camera_wpos = mul(u_camInvView, vec4(0, 0, 0, 1));
			vec3 view = normalize(camera_wpos.xyz - v_wpos.xyz);
			
			vec4 specularColor = (f0 - f0 * metallic) + albedo * metallic;
			vec4 diffuseColor = albedo - albedo * metallic;
			
			float ndotv = saturate(dot(normal, view));
			vec3 direct_diffuse;
			vec3 direct_specular;
			PBR_ComputeDirectLight(normal, -u_lightDirFov.xyz, view, u_lightRgbAndIndirectIntensity.rgb, f0, roughness, direct_diffuse, direct_specular);

			vec3 indirect_diffuse = PBR_ComputeIndirectDiffuse(u_irradiance_map, normal, diffuseColor.rgb);
			vec3 rv = reflect(-view.xyz, normal.xyz);
			vec3 indirect_specular = PBR_ComputeIndirectSpecular(u_radiance_map, specularColor.rgb, roughness, ndotv, rv);
			
			float ndotl = -dot(normal, u_lightDirFov.xyz);
			float shadow = directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1), ndotl);
			float fog_factor = getFogFactor(camera_wpos.xyz / camera_wpos.w, u_fogColorDensity.w, v_wpos.xyz, u_fogParams);
			vec3 lighting = 
				emission * albedo +
				direct_diffuse * diffuseColor.rgb * shadow + 
				direct_specular * specularColor.rgb * shadow + 
				indirect_diffuse * u_lightRgbAndIndirectIntensity.w + 
				indirect_specular * u_lightRgbAndIndirectIntensity.w +
				0
				;
			float alpha = clamp(color.a, 0, 1);
			#ifdef ALPHA_CUTOUT
				if(alpha < u_alphaRef) discard;
			#endif
				
			gl_FragColor.rgb = mix(lighting, u_fogColorDensity.rgb, fog_factor);
			gl_FragColor.w = alpha;
		#endif
	#endif
}
