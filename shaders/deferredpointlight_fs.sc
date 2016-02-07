$input v_wpos, v_texcoord0, v_view, v_pos_radius, v_color_attn, v_dir_fov, v_specular // in...

#include "common.sh"

SAMPLER2D(u_gbuffer0, 0);
SAMPLER2D(u_gbuffer1, 1);
SAMPLER2D(u_gbuffer2, 2);
SAMPLER2D(u_gbuffer_depth, 3);
SAMPLER2D(u_texShadowmap, 4);

uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_fogParams;
uniform mat4 u_camInvViewProj;

vec4 getViewPos(vec2 texCoord)
{
	float z = texture2D(u_gbuffer_depth, texCoord).r;
	#if BGFX_SHADER_LANGUAGE_HLSL
		z = z;
	#else
		z = z * 2.0 - 1.0;
	#endif // BGFX_SHADER_LANGUAGE_HLSL
	vec4 posProj = vec4(texCoord * 2 - 1, z, 1.0);
	#if BGFX_SHADER_LANGUAGE_HLSL
		posProj.y = -posProj.y;
	#endif // BGFX_SHADER_LANGUAGE_HLSL
	
	vec4 posView = mul(u_camInvViewProj, posProj);
	
	posView /= posView.w;
	return posView;
}


vec3 calcLight(vec4 dirFov, vec3 _wpos
	, vec3 _normal
	, vec3 _view
	, vec2 uv
	, vec3 light_pos
	, float light_radius
	, vec3 light_color
	, float attn_param
	, vec3 light_specular)
{
	vec3 lp = light_pos.xyz - _wpos;
	float dist = length(lp);
	float attn = pow(max(0, 1 - dist / light_radius), attn_param);
	
	vec3 toLightDir = normalize(lp);
	
	if(dirFov.w < 3.14159)
	{
		float cosDir = dot(normalize(dirFov.xyz), normalize(-toLightDir));
		float cosCone = cos(dirFov.w * 0.5);
	
		if(cosDir < cosCone)
			discard;
		attn *= (cosDir - cosCone) / (1 - cosCone);
	}

	vec4 materialSpecularShininess = vec4(1, 1, 1, 4); // todo use uniform
	vec2 lc = lit(toLightDir, _normal, _view, materialSpecularShininess.w);
	vec3 rgb = 
		attn * (light_color * saturate(lc.x) 
		+ light_specular.xyz * materialSpecularShininess.xyz *
		#ifdef SPECULAR_TEXTURE
			texture2D(u_texSpecular, uv).rgb * 
		#endif
		saturate(lc.y));
	return rgb;
}


void main()
{
	vec4 prj = mul(u_viewProj, vec4(v_wpos, 1.0)); // todo: get rid of this
	prj.y = -prj.y;
	prj /= prj.w;
	
	vec3 normal = texture2D(u_gbuffer1, (prj.xy + 1) * 0.5).xyz * 2 - 1;
	vec4 color = texture2D(u_gbuffer0, (prj.xy + 1) * 0.5);

	vec4 wpos = getViewPos((prj.xy + 1) * 0.5);
	
	float ndotl = -dot(normal, v_dir_fov.xyz);
	vec3 view = normalize(v_view);
	vec3 diffuse = color.rgb * calcLight(v_dir_fov
		, wpos, normal
		, view
		, prj.xy
		, v_pos_radius.xyz
		, v_pos_radius.w
		, v_color_attn.xyz
		, v_color_attn.w
		, v_specular.xyz); 

	gl_FragColor.xyz = diffuse;
	gl_FragColor.w = 1;
}
