$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2,  v_color

#include "common.sh"

SAMPLER2D(u_texColor, 0);
#ifdef NORMAL_MAPPING
	SAMPLER2D(u_texNormal, 1);
#endif
#ifdef SPECULAR_TEXTURE
	SAMPLER2D(u_texSpecular, 2);
#endif
SAMPLER2D(u_texShadowmap, 3);
uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_lightSpecular;
uniform vec4 u_materialSpecularShininess;
uniform vec4 u_attenuationParams;
uniform vec4 u_fogParams;


void main()
{     
	#ifdef SHADOW
		vec4 color = texture2D(u_texColor, v_texcoord0);
		if(color.a < 0.3)
			discard;
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
		#else
			wnormal = vec3(0.0, 1.0, 0.0);
		#endif
		wnormal = mul(tbn, wnormal);
		vec3 view = normalize(v_view);

		vec4 color = /*toLinear*/(texture2D(u_texColor, v_texcoord0) ) * v_color.rgba;
		if(color.a < 0.3)
			discard;
					 
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
				, u_materialSpecularShininess
				, u_lightSpecular
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
				, u_lightSpecular
				, wnormal
				, u_materialSpecularShininess
				, texture_specular);
			diffuse = diffuse.xyz * color.rgb;
			float ndotl = -dot(mul(tbn, wnormal), u_lightDirFov.xyz);
			diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0), ndotl); 
		#endif

		#ifdef MAIN
			vec3 ambient = u_ambientColor.rgb * color.rgb;
		#else
			vec3 ambient = vec3(0, 0, 0);
		#endif  

		vec4 view_pos = mul(u_view, vec4(v_wpos, 1.0));
		float fog_factor = getFogFactor(view_pos.z / view_pos.w, u_fogColorDensity.w, v_wpos.y, u_fogParams);
		#ifdef POINT_LIGHT
			gl_FragColor.xyz = (1 - fog_factor) * (diffuse + ambient);
		#else
			gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
		#endif
		gl_FragColor.w = 1.0;
	#endif                  
}
