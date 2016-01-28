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


vec3 calcLight(vec4 dirFov, vec3 _wpos, vec3 _normal, vec3 _view, vec2 uv)
{
	vec3 lp = u_lightPosRadius.xyz - _wpos;
	float radius = u_lightPosRadius.w;
	float dist = length(lp);
	float attn = pow(max(0, 1 - dist / u_lightPosRadius.w), u_lightRgbAttenuation.w);
	
	vec3 toLightDir = normalize(lp);
	
	if(dirFov.w < 3.14159)
	{
		float cosDir = dot(normalize(dirFov.xyz), normalize(-toLightDir));
		float cosCone = cos(dirFov.w * 0.5);
	
		if(cosDir < cosCone)
			discard;
		attn *= (cosDir - cosCone) / (1 - cosCone);
	}
		
   vec2 bln = blinn(toLightDir, _normal, _view);
	vec4 lc = lit(bln.x, bln.y, u_materialSpecularShininess.w);
	vec3 rgb = 
		attn * (u_lightRgbAttenuation.xyz * saturate(lc.y) 
		+ u_lightSpecular.xyz * u_materialSpecularShininess.xyz *
		#ifdef SPECULAR_TEXTURE
			texture2D(u_texSpecular, uv).rgb * 
		#endif
		saturate(lc.z));
	return rgb;
}


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
					
		vec3 normal;
		#ifdef NORMAL_MAPPING
			normal.xz = texture2D(u_texNormal, v_texcoord0).xy * 2.0 - 1.0;
			normal.y = sqrt(1.0 - dot(normal.xz, normal.xz) );
		#else
			normal = vec3(0.0, 1.0, 0.0);
		#endif
		vec3 view = normalize(v_view);

		vec4 color = /*toLinear*/(texture2D(u_texColor, v_texcoord0) ) * v_color.rgba;
		if(color.a < 0.3)
			discard;
					 
		vec3 diffuse;
		#ifdef POINT_LIGHT
			diffuse = calcLight(u_lightDirFov, v_wpos, mul(tbn, normal), view, v_texcoord0);
			diffuse = diffuse.xyz * color.rgb;
			#ifdef HAS_SHADOWMAP
				diffuse = diffuse * pointLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0), u_lightDirFov.w); 
			#endif
		#else
			diffuse = calcGlobalLight(u_lightDirFov.xyz, u_lightRgbAttenuation.rgb, mul(tbn, normal));
			diffuse = diffuse.xyz * color.rgb;
			float ndotl = -dot(mul(tbn, normal), u_lightDirFov.xyz);
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
