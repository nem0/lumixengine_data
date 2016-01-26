$input v_wpos, v_common, v_texcoord0

#include "common.sh"

SAMPLER2D(u_texColor, 0);
SAMPLER2D(u_texShadowmap, 2);

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_lightSpecular;
uniform vec4 u_materialSpecularShininess;
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
	vec4 color = /*toLinear*/(texture2D(u_texColor, v_texcoord0) );
	if(color.a < 0.3)
		discard;
	#ifdef DEFERRED
		gl_FragData[0] = color * vec4(v_common, 1);
		gl_FragData[1].xyzw = vec4(0, 1, 0, 1);
		gl_FragData[2] = vec4(1, 1, 1, 1);
	#else
		vec3 diffuse;
		#ifdef POINT_LIGHT
			vec3 shading = calcLight(u_lightDirFov, v_wpos);
			diffuse = color * v_common * shading;
			vec3 ambient = vec3(0, 0, 0);
		#else
			vec3 shadow = directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0), 1.0);;
			diffuse = color * v_common *  shadow * u_lightRgbAttenuation.rgb;
			vec3 ambient = u_ambientColor.rgb * color.rgb;
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
