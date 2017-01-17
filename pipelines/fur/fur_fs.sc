$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2

#include "common.sh"

SAMPLER2D(u_texColor, 0);
#ifdef NORMAL_MAPPING
	SAMPLER2D(u_texNormal, 1);
#endif
#ifdef MAIN
	SAMPLER2D(u_texShadowmap, 15);
#endif
#ifdef FUR
	SAMPLERCUBE(u_irradiance_map, 15);
	SAMPLERCUBE(u_radiance_map, 14);
	SAMPLER2D(u_texShadowmap, 13);
#endif

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_materialColor;
uniform vec4 u_attenuationParams;
uniform vec4 u_fogParams;
uniform vec4 u_layer;
uniform vec4 u_alphaMultiplier;
uniform vec4 u_darkening;
uniform vec4 u_roughnessMetallic;


void main()
{     
	vec4 color = texture2D(u_texColor, v_texcoord0);
	color.xyz *= u_materialColor.rgb;
	#ifdef DEFERRED
		gl_FragData[0].rgb = color.rgb;
		gl_FragData[0].w = u_roughnessMetallic.x;
		mat3 tbn = mat3(
			normalize(v_tangent),
			normalize(v_normal),
			normalize(v_bitangent)
			);
		tbn = transpose(tbn);
		vec3 normal;
		#ifdef NORMAL_MAPPING
			normal.xzy = texture2D(u_texNormal, v_texcoord0).xyz * 2.0 - 1.0;
			normal = normalize(mul(tbn, normal));
		#else
			normal = normalize(v_normal.xyz);
		#endif
		gl_FragData[1].xyz = (normal + 1) * 0.5; // todo: store only xz 
		gl_FragData[1].w = u_roughnessMetallic.y;
		gl_FragData[2] = vec4(1, 0, 0, 1);
	#else
		#ifdef SHADOW
			float depth = v_common2.z/v_common2.w;
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
				wnormal.xz = texture2D(u_texNormal, v_texcoord0).xy * 2.0 - 1.0;
				wnormal.y = sqrt(1.0 - dot(wnormal.xz, wnormal.xz) );
				wnormal = mul(tbn, wnormal);
			#else
				wnormal = normalize(v_normal.xyz);
			#endif
			
			float f0 = 0.04;
			
			vec3 normal = wnormal;
			vec4 albedo = color;
			float roughness = u_roughnessMetallic.x;
			float metallic = u_roughnessMetallic.y;
			
			vec4 camera_wpos = mul(u_camInvView, vec4(0, 0, 0, 1));
			vec3 view = normalize(camera_wpos.xyz - v_wpos.xyz);
			
			vec4 specularColor = (f0 - f0 * metallic) + albedo * metallic;
			vec4 diffuseColor = albedo - albedo * metallic;
			
			float ndotv = saturate(dot(normal, view));
			vec3 direct_diffuse;
			vec3 direct_specular;
			PBR_ComputeDirectLight(normal, -u_lightDirFov.xyz, view, u_lightRgbAttenuation.rgb, f0, roughness, direct_diffuse, direct_specular);

			vec3 indirect_diffuse = PBR_ComputeIndirectDiffuse(u_irradiance_map, normal, diffuseColor.rgb);
			vec3 rv = reflect(-view.xyz, normal.xyz);
			vec3 indirect_specular = PBR_ComputeIndirectSpecular(u_radiance_map, specularColor.rgb, roughness, ndotv, rv);
			
			float ndotl = -dot(normal, u_lightDirFov.xyz);
			float shadow = 1; //directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1), ndotl);
			float fog_factor = getFogFactor(camera_wpos.xyz / camera_wpos.w, u_fogColorDensity.w, v_wpos.xyz, u_fogParams);
			vec3 lighting = 
				direct_diffuse * diffuseColor.rgb * shadow + 
				direct_specular * specularColor.rgb * shadow + 
				indirect_diffuse + 
				indirect_specular +
				0
				;
			float alpha = clamp(color.a * u_alphaMultiplier.x - u_layer.x, 0, 1);
			#ifdef ALPHA_CUTOUT
				if(alpha < u_alphaRef) discard;
			#endif
				
			gl_FragColor.rgb = mix(lighting, u_fogColorDensity.rgb, fog_factor);
			gl_FragColor.w = alpha;
		#endif       
	#endif		
}
