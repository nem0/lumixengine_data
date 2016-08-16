$input v_wpos

#include "common.sh"

SAMPLER2D(u_texColor, 0);
SAMPLER2D(u_gbuffer_depth, 15);

uniform mat4 u_camInvViewProj;
uniform mat4 u_decalMatrix;

vec3 getViewPos(vec2 texCoord)
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
	return posView.xyz;
}

void main()
{
	vec4 prj = mul(u_viewProj, vec4(v_wpos, 1.0)); // todo: get rid of this
	prj.y = -prj.y;
	prj /= prj.w;
	vec3 wpos = getViewPos((prj.xy + 1) * 0.5);
	
	vec3 tmp = mul(u_decalMatrix, vec4(wpos, 1)).xyz;
	
	if(any(greaterThan(abs(tmp), vec3_splat(1.0)))) discard;
	
	vec4 color = texture2D(u_texColor, tmp.xy * 0.5 - 0.5);
	if(color.a < 0.5) discard;
	gl_FragColor = color;
}
