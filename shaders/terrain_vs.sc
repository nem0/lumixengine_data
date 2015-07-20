$input a_position, a_normal, a_tangent, a_texcoord0, i_data0, i_data1
$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_texcoord1

#include "common.sh"

uniform usampler2D u_heightmap;
//SAMPLER2D(u_heightmap, 0);
uniform vec4 u_relCamPos;
uniform vec4 u_mapSize;
uniform vec4 u_terrainScale;
uniform mat4 u_terrainMatrix;

float computeWeight(vec3 pos, vec3 quad_min, vec2 morph_const)
{
	vec3 cp = u_relCamPos.xyz;
	cp.y = 0.0;
	vec3 pp = pos;
	pp.y = 0.0;           
	
	float dist = distance(cp, quad_min + pp.xyz);
	float weight = (dist - morph_const.y) / (morph_const.x - morph_const.y);
	//return 0.0;
	return clamp(weight, 0.0, 1.0);
}

void main()
{

	float m = i_data0.w / 8.0;
	v_wpos = a_position;  
	v_wpos.x *= i_data0.w;
	v_wpos.z *= i_data0.w;
	
	float fraction_x = fract(v_wpos.x / m) * m;
	float fraction_z = fract(v_wpos.z / m) * m;

	float weight = computeWeight(v_wpos, i_data0.xyz, i_data1.xy);

	v_wpos.x = v_wpos.x - weight * fraction_x;
	v_wpos.z = v_wpos.z - weight * fraction_z;
	v_wpos += i_data0.xyz;

	vec2 uv = v_wpos.xz / (u_mapSize.x);
	uv.x += 0.5/u_mapSize.x;
	uv.y += 0.5/u_mapSize.x;
	
	v_texcoord1 = uv;

	v_wpos.y = u_terrainScale.y * texture(u_heightmap, uv).x / 65535.0;
	v_wpos.x *= u_terrainScale.x;
	v_wpos.z *= u_terrainScale.z;

	gl_Position = mul(u_viewProj, mul(u_terrainMatrix, vec4(v_wpos, 1.0))); 

	v_normal = mul(u_terrainMatrix, vec4(0.0, 1.0, 0.0, 0.0) ).xyz;
	v_tangent = mul(u_terrainMatrix, vec4(1.0, 0.0, 0.0, 0.0) ).xyz;
    v_bitangent = cross(v_normal, v_tangent);
	v_texcoord0 = uv * u_mapSize.x;
    v_wpos = mul(u_terrainMatrix, vec4(v_wpos, 1.0) ).xyz;
	v_view = mul(u_view, vec4(0.0, 0.0, 1.0, 0.0)).xyz;
}
