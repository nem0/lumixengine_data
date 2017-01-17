$input a_position, a_normal, a_tangent, a_texcoord0, i_data0, i_data1, i_data2, i_data3, i_data4
$output v_wpos, v_normal, v_common, v_texcoord0, v_view

#include "common.sh"

uniform vec4 u_time;
uniform vec4 u_grassMaxDist;

SAMPLER2D(u_texNoise, 1);

// https://github.com/admazzola/animated-grass-shader-jme3/blob/master/src/grass/MovingGrass.vert
void main()
{
	const float frequency = 2;
	const float move_factor = 0.06;
	// possible future control from engine
	const float wind_strength = 1.0;
	const vec3 wind_dir = vec3(1, 0, 0);

	v_common = vec3(a_position.y, a_position.y, a_position.y);
 	v_texcoord0 = a_texcoord0;
	
	mat4 model;
	model[0] = i_data0;
	model[1] = i_data1;
	model[2] = i_data2;
	model[3] = i_data3;
	
	v_normal.xyz = i_data4.xyz;
	
	float min_dist = u_grassMaxDist.x;
	float scale_dist = 10;
	vec3 view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - instMul(model, vec4(a_position, 1.0) ).xyz;
	float scale = clamp(1 - (length(view) - (min_dist - scale_dist))/scale_dist, 0, 1);
	
	vec3 displaced_vertex = scale*a_position;
	if(a_position.y>=0.1)
	{
		float len = length(displaced_vertex);
		int totalTime = int(u_time.x);
		int pixelY = int(totalTime/64);
		int pixelX = int(totalTime / -(pixelY + 0.00001));
		float noiseFactor = texture2DLod(u_texNoise, vec2( pixelX*10, pixelY*10 ), 0).r;
		vec3 wpos = instMul(model, vec4(displaced_vertex, 1.0) ).xyz;
		displaced_vertex.x += move_factor * sin(frequency * u_time.x * texture2DLod(u_texNoise, wpos.xz*50.0, 0).r + len) + (wind_strength * noiseFactor * wind_dir.x)/10.0;
		displaced_vertex.z += move_factor * cos(frequency * u_time.x * texture2DLod(u_texNoise, wpos.zx*50.0, 0).r + len) + (wind_strength * noiseFactor * wind_dir.y)/10.0;
	}
	v_wpos = instMul(model, vec4(displaced_vertex, 1.0)).xyz;
	v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - v_wpos;
	gl_Position = mul(u_viewProj, vec4(v_wpos, 1.0));
}

