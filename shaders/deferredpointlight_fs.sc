$input v_wpos, v_texcoord0, v_view // in...

#include "common.sh"

SAMPLER2D(u_gbuffer0, 0);
SAMPLER2D(u_gbuffer1, 1);
SAMPLER2D(u_gbuffer2, 2);
SAMPLER2D(u_gbuffer_depth, 3);
SAMPLER2D(u_texShadowmap, 4);

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbInnerR;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_lightSpecular;
uniform vec4 u_fogParams;
uniform mat4 u_camInvViewProj;
uniform vec4 u_attenuationParams;
uniform vec4 u_materialSpecularShininess;


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


vec3 calcLight(vec4 dirFov, vec3 _wpos, vec3 _normal, vec3 _view, vec2 uv)
{
	vec3 lp = u_lightPosRadius.xyz - _wpos;
	float radius = u_lightPosRadius.w;
	float dist = length(lp);
	float attn = pow(max(0, 1 - dist / u_attenuationParams.x), u_attenuationParams.y);
	
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
	vec2 bln = blinn(toLightDir, _normal, _view);
	vec4 lc = lit(bln.x, bln.y, materialSpecularShininess.w);
	vec3 rgb = 
		attn * (u_lightRgbInnerR.xyz * saturate(lc.y) 
		+ u_lightSpecular.xyz * materialSpecularShininess.xyz *
		#ifdef SPECULAR_TEXTURE
			texture2D(u_texSpecular, uv).rgb * 
		#endif
		saturate(lc.z));
	return rgb;
}


void main()
{
	v_texcoord0.y = 1 - v_texcoord0.y; // todo
	vec4 prj = mul(u_viewProj, vec4(v_wpos, 1.0)); // todo: get rid of this
	prj.y = -prj.y;
	prj /= prj.w;
	
	vec3 normal = texture2D(u_gbuffer1, (prj.xy + 1) * 0.5).xyz * 2 - 1;
	vec4 color = texture2D(u_gbuffer0, (prj.xy + 1) * 0.5);

	vec4 wpos = getViewPos((prj.xy + 1) * 0.5);
	
	float ndotl = -dot(normal, u_lightDirFov.xyz);
	vec3 view = normalize(v_view);
	vec3 diffuse = color.rgb * calcLight(u_lightDirFov, wpos, normal, view, prj.xy); 

	gl_FragColor.xyz = diffuse;
	gl_FragColor.w = 1;
}
