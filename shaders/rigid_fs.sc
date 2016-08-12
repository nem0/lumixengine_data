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
#ifdef SPECULAR_TEXTURE
	SAMPLER2D(u_texSpecular, 2);
#endif
#ifdef BUMP_TEXTURE
	SAMPLER2D(u_texBump, 3);
#endif
#ifndef SHADOW
	SAMPLER2D(u_texShadowmap, 15);
#endif
uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity;
uniform vec4 u_lightSpecular;
uniform vec4 u_materialColorShininess;
uniform vec4 u_attenuationParams;
uniform vec4 u_fogParams;
uniform vec4 u_parallaxScale;


#ifdef BUMP_TEXTURE
vec2 parallaxMapping(sampler2D bump_map, vec2 texCoords, vec3 viewDir)
{ 
	float height_scale = u_parallaxScale.x;
    const float minLayers = 10;
    const float maxLayers = 20;
    float numLayers = mix(maxLayers, minLayers, abs(viewDir.y));  
    float layerDepth = 1.0 / numLayers;
    float currentLayerDepth = 0.0;
    vec2 P = viewDir.xz * height_scale; 
    vec2 deltaTexCoords = P / numLayers;
  
    vec2  currentTexCoords     = texCoords;
    float currentDepthMapValue = texture2D(bump_map, currentTexCoords).r;
      
	#if BGFX_SHADER_LANGUAGE_HLSL
	[unroll(20)]
	#endif
    while(currentLayerDepth < currentDepthMapValue)
    {
        currentTexCoords += deltaTexCoords;
        currentDepthMapValue = texture2D(bump_map, currentTexCoords).r;  
        currentLayerDepth += layerDepth;  
    }
    
    vec2 prevTexCoords = currentTexCoords - deltaTexCoords;

    float afterDepth  = currentDepthMapValue - currentLayerDepth;
    float beforeDepth = texture2D(bump_map, prevTexCoords).r - currentLayerDepth + layerDepth;
 
    float weight = afterDepth / (afterDepth - beforeDepth);
    vec2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);

    return finalTexCoords;
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
	#else
		vec4 color = vec4(1, 1, 1, 1);
	#endif
	#ifdef ALPHA_CUTOUT
		if(color.a < u_alphaRef) discard;
	#endif
	color.xyz *= u_materialColorShininess.rgb;
	#ifdef DEFERRED
		gl_FragData[0] = vec4(color.rgb, 1);
		vec3 normal;
		#ifdef NORMAL_MAPPING
			mat3 tbn = mat3(
				normalize(v_tangent),
				normalize(v_normal),
				normalize(v_bitangent)
				);
			tbn = transpose(tbn);
			normal.xzy = texture2D(u_texNormal, tex_coords).xyz * 2.0 - 1.0;
			normal = normalize(mul(tbn, normal));
		#else
			normal = normalize(v_normal);
		#endif
		gl_FragData[1].xyz = (normal + 1) * 0.5; // todo: store only xz 
		gl_FragData[1].w = 1;
		float spec = u_materialColorShininess.g / 64.0;
		float shininess = u_materialColorShininess.a / 64.0;
		#ifdef SPECULAR_TEXTURE
			spec *= texture2D(u_texSpecular, tex_coords).g;
		#endif
		gl_FragData[2] = vec4(spec, shininess, 0, 1);
	#else
		#ifdef SHADOW
			float depth = v_common2.z / v_common2.w;
			gl_FragColor = vec4_splat(depth);
		#else
			mat3 tbn = mat3(
						normalize(v_tangent),
						normalize(v_normal),
						normalize(v_bitangent)
						);
			tbn = transpose(tbn);
						
			vec3 wnormal;
			#ifdef NORMAL_MAPPING
				wnormal.xzy = texture2D(u_texNormal, tex_coords).xyz * 2.0 - 1.0;
				wnormal = mul(tbn, wnormal);
			#else
				wnormal = normalize(v_normal.xyz);
			#endif
			vec3 view = normalize(v_view);
					 
			vec3 texture_specular = 
			#ifdef SPECULAR_TEXTURE
				texture2D(u_texSpecular, tex_coords).rgb;
			#else
				vec3(1, 1, 1);
			#endif
			vec3 diffuse;
			#ifdef POINT_LIGHT
				diffuse = shadePointLight(u_lightDirFov
				, v_wpos
				, wnormal
				, view
				, tex_coords
				, u_lightPosRadius
				, u_lightRgbAttenuation
				, u_materialColorShininess
				, u_lightSpecular.rgb
				, texture_specular
				);
				diffuse = diffuse.xyz * color.rgb;
				#ifdef HAS_SHADOWMAP
					diffuse = diffuse * pointLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0), u_lightDirFov.w); 
				#endif
			#else
				diffuse = shadeDirectionalLight(u_lightDirFov.xyz
					, view
					, u_lightRgbAttenuation.rgb
					, u_lightSpecular.rgb
					, wnormal
					, u_materialColorShininess
					, texture_specular);
				diffuse = diffuse.xyz * color.rgb;
				float ndotl = -dot(wnormal, u_lightDirFov.xyz);
				diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0), ndotl); 
			#endif

			#ifdef MAIN
				vec3 ambient = u_ambientColor.rgb * color.rgb;
			#else
				vec3 ambient = vec3(0, 0, 0);
			#endif  

			vec4 camera_wpos = mul(u_invView, vec4(0, 0, 0, 1));
			float fog_factor = getFogFactor(camera_wpos.xyz / camera_wpos.w
				, u_fogColorDensity.w
				, v_wpos.xyz
				, u_fogParams);
			#ifdef POINT_LIGHT
				gl_FragColor.xyz = (1 - fog_factor) * (diffuse + ambient);
			#else
				gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
			#endif
			gl_FragColor.w = 1.0;
			#ifdef BUMP_TEXTURE
				vec3 tmp = normalize(v_tangent_view_pos);
				//gl_FragColor = vec4(tmp.x, tmp.y, tmp.z, 1);
			#endif
		#endif       
	#endif		
}
