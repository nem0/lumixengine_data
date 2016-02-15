$input v_wpos, v_common, v_texcoord0, v_view

#include "common.sh"

SAMPLER2D(u_texColor, 0);
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
uniform vec4 u_fogParams;
uniform vec4 u_attenuationParams;


vec3 calcLight(vec4 dirFov, vec3 _wpos)
{
	vec3 lp = u_lightPosRadius.xyz - _wpos;
	float radius = u_lightPosRadius.w;
	float dist = length(lp);
	float attn = pow(max(0, 1 - dist / u_lightPosRadius.x), u_lightRgbAttenuation.w);
	
	vec3 toLightDir = normalize(lp);
	
	if(dirFov.w < 3.14159)
	{
		float cosDir = dot(normalize(dirFov.xyz), normalize(-toLightDir));
		float cosCone = cos(dirFov.w * 0.5);
	
		if(cosDir < cosCone)
			discard;
		attn *= (cosDir - cosCone) / (1 - cosCone);
	}
		
	return attn * u_lightRgbAttenuation.xyz;
}

void main()
{
	vec4 color = texture2D(u_texColor, v_texcoord0);
	#ifdef ALPHA_CUTOUT
		if(color.a < u_alphaRef) discard;
	#endif
	color.rgb *= u_materialColorShininess.rgb;
	#ifdef DEFERRED
		gl_FragData[0] = color;
		vec3 normal = vec3(0, 1, 0);
		gl_FragData[1].xyz = (normal + 1) * 0.5; // todo: store only xz 
		gl_FragData[1].w = 1;
		float spec = u_materialColorShininess.g / 64.0;
		float shininess = u_materialColorShininess.a / 64.0;
		gl_FragData[2] = vec4(spec, shininess, 0, 1);

	#else
		vec3 wnormal = vec3(0, 1, 0);
		vec3 view = normalize(v_view);
					 
		vec3 texture_specular = vec3(1, 1, 1);
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
