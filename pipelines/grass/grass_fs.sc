$input v_wpos, v_normal, v_common, v_texcoord0, v_view

#include "common.sh"

SAMPLER2D(u_texColor, 0);


uniform vec4 u_materialColor;
uniform vec4 u_roughnessMetallic;


void main()
{
	vec4 color = texture2D(u_texColor, v_texcoord0);
	#ifdef ALPHA_CUTOUT
		if(color.a < u_alphaRef) discard;
	#endif
	color.rgb *= u_materialColor.rgb;
	#if 1 // darkening
		color.rgb *= min(1.0, 2 * v_common.y + 0.5);
	#endif
	gl_FragData[0].rgb = color.rgb;
	gl_FragData[0].w = u_roughnessMetallic.x;
	vec3 normal = v_normal;
	gl_FragData[1].xyz = (normal + 1) * 0.5; // todo: store only xz 
	gl_FragData[1].w = u_roughnessMetallic.y;
	gl_FragData[2] = vec4(1, 0, 0, 1);
}
