#ifdef SKINNED
	$input a_position, a_normal, a_tangent, a_texcoord0, a_weight, a_indices
	$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2

	uniform mat4 u_boneMatrices[128];
#else
	$input a_position, a_normal, a_tangent, a_texcoord0, i_data0, i_data1, i_data2, i_data3
	$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2
#endif

#include "common.sh"

#ifdef WIND_ANIMATION
	SAMPLER2D(u_texNoise, 0);
	uniform vec4 u_time;
#endif

void main()
{
	const float MOVE_FACTOR = 0.26;
	const float FREQUENCY = 2;
	const float WIND_STRENGTH = 1.0;
	const vec3 WIND_DIR = vec3(1, 0, 0);
	#ifdef SKINNED
		mat4 model = 
			mul(u_model[0], a_weight.x * u_boneMatrices[int(a_indices.x)] + 
			a_weight.y * u_boneMatrices[int(a_indices.y)] +
			a_weight.z * u_boneMatrices[int(a_indices.z)] +
			a_weight.w * u_boneMatrices[int(a_indices.w)]);
	#else
		mat4 model;
		model[0] = i_data0;
		model[1] = i_data1;
		model[2] = i_data2;
		model[3] = i_data3;
	#endif

	vec3 position = a_position;
	#ifdef WIND_ANIMATION
		if (position.y>=0.1)
		{
			float len = length(position);
			int totalTime = int(u_time.x);
			int pixelY = int(totalTime/64);
			int pixelX = int(totalTime / -(pixelY + 1e-5));
			float noiseFactor = texture2DLod(u_texNoise, vec2( pixelX*10, pixelY*10 ), 0).r;
			vec3 wpos = instMul(model, vec4(position, 1.0) ).xyz;
			position.x += MOVE_FACTOR * sin(FREQUENCY * u_time.x * texture2DLod(u_texNoise, wpos.xz*50.0, 0).r + len) + (WIND_STRENGTH * noiseFactor * WIND_DIR.x)/10.0;
			position.z += MOVE_FACTOR * cos(FREQUENCY * u_time.x * texture2DLod(u_texNoise, wpos.zx*50.0, 0).r + len) + (WIND_STRENGTH * noiseFactor * WIND_DIR.y)/10.0;
		}
	#endif	

	#ifdef SKINNED
		v_wpos = mul(model, vec4(position, 1.0) ).xyz;
	#else
		v_wpos = instMul(model, vec4(position, 1.0) ).xyz;
	#endif
	
	#ifndef SHADOW
		vec4 normal = a_normal * 2.0 - 1.0;
		vec4 tangent = a_tangent * 2.0 - 1.0;

		v_normal = instMul(model, vec4(normal.xyz, 0.0) ).xyz;
		v_tangent = instMul(model, vec4(tangent.xyz, 0.0) ).xyz;
		v_bitangent = cross(v_normal, v_tangent);
		v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - v_wpos;
	#endif
	v_texcoord0 = a_texcoord0;
	v_common2 = mul(u_viewProj, vec4(v_wpos, 1.0) ); 
	gl_Position =  v_common2;
}
