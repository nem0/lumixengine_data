$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2,  v_color

#include "common.sh"

SAMPLER2D(u_texColor, 0);
#ifdef NORMAL_MAPPING
	SAMPLER2D(u_texNormal, 1);
#endif
#ifdef SPECULAR_TEXTURE
	SAMPLER2D(u_texSpecular, 2);
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


void main()
{     
	vec4 color = texture2D(u_texColor, v_texcoord0);
	#ifdef ALPHA_CUTOUT
		if(color.a < u_alphaRef) discard;
	#endif
	color.xyz *= v_color.rgb * u_materialColorShininess.rgb;
	#ifdef DEFERRED
		gl_FragData[0] = color;
		vec3 normal;
		#ifdef NORMAL_MAPPING
			mat3 tbn = mat3(
				normalize(v_tangent),
				normalize(v_normal),
				normalize(v_bitangent)
				);
			tbn = transpose(tbn);
			normal.xzy = texture2D(u_texNormal, v_texcoord0).xyz * 2.0 - 1.0;
			normal = normalize(mul(tbn, normal));
		#else
			normal = normalize(v_normal);
		#endif
		gl_FragData[1].xyz = (normal + 1) * 0.5; // todo: store only xz 
		gl_FragData[1].w = 1;
		float spec = u_materialColorShininess.g / 64.0;
		float shininess = u_materialColorShininess.a / 64.0;
		#ifdef SPECULAR_TEXTURE
			spec *= texture2D(u_texSpecular, v_texcoord0).g;
		#endif
		gl_FragData[2] = vec4(spec, shininess, 0, 1);
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
				wnormal.xzy = texture2D(u_texNormal, v_texcoord0).xyz * 2.0 - 1.0;
				wnormal = mul(tbn, wnormal);
			#else
				wnormal = normalize(v_normal.xyz);
			#endif
			vec3 view = normalize(v_view);

			vec3 texture_specular = 
			#ifdef SPECULAR_TEXTURE
				texture2D(u_texSpecular, v_texcoord0).rgb;
			#else
				vec3(1, 1, 1);
			#endif					 
			vec3 diffuse;
			#ifdef POINT_LIGHT
				diffuse = shadePointLight(u_lightDirFov
					, v_wpos
					, wnormal
					, view
					, v_texcoord0
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

			vec4 camera_wpos = mul(u_invView, vec4(0, 0, 0, 1.0));
			float fog_factor = getFogFactor(camera_wpos.xyz / camera_wpos.w, u_fogColorDensity.w, v_wpos.xyz, u_fogParams);
			#ifdef POINT_LIGHT
				gl_FragColor.xyz = (1 - fog_factor) * (diffuse + ambient);
			#else
				gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
			#endif
			gl_FragColor.w = 1.0;
		#endif                  
	#endif                  
}
