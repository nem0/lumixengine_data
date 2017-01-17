#ifdef SUBIMAGE
	$input a_position, a_color, a_texcoord0, i_data0, i_data1, i_data2, i_data3
	$output v_wpos, v_texcoord0, v_texcoord1, v_common, v_common2
#else
	$input a_position, a_color, a_texcoord0, i_data0, i_data1
	$output v_wpos, v_texcoord0, v_texcoord1, v_common
#endif

#include "common.sh"

#ifdef LOCAL_SPACE
	uniform mat4 u_emitterMatrix;
#endif

void main()
{
	vec4 up2 = vec4(u_invView[0][1], u_invView[1][1], u_invView[2][1], u_invView[3][1]);
	vec4 right2 = -vec4(u_invView[0][0], u_invView[1][0], u_invView[2][0], u_invView[3][0]);

	float rot = i_data1.y;
	float c = cos(rot);
	float s = sin(rot);
	
	vec4 up = c * up2 + s * right2;
	vec4 right = -s * up2 + c * right2;
	
	#ifdef LOCAL_SPACE
		vec3 wpos = mul(u_emitterMatrix, vec4(i_data0.xyz, 1)).xyz + (up * a_position.y + right * a_position.x).xyz * i_data0.w;
	#else
		vec3 wpos = i_data0.xyz + (up * a_position.y + right * a_position.x).xyz * i_data0.w;
	#endif
	v_wpos = wpos;
	#ifdef SUBIMAGE
		v_texcoord0 = a_texcoord0 * i_data2.zw + i_data2.xy;
		v_texcoord1 = a_texcoord0 * i_data2.zw + i_data3.xy;
		v_common2 = vec4(i_data3.z, 0, 0, 0);
	#else
		v_texcoord0 = a_texcoord0;
	#endif
	
	v_common = i_data1.xyz;
	gl_Position = mul(u_viewProj, vec4(wpos, 1.0) );	
}
