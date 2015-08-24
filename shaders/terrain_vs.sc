$input a_position, a_normal, a_tangent, a_texcoord0, i_data0, i_data1
$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_texcoord1, v_common

#include "common.sh"

//uniform sampler2D u_texHeightmap;
SAMPLER2D(u_texHeightmap, 0);
uniform vec4 u_relCamPos;
uniform vec4 u_terrainParams;
uniform vec4 u_terrainScale;
uniform mat4 u_terrainMatrix;

vec3 computeWeight(vec3 pos, vec3 quad_min, vec2 morph_const)
{
	vec3 r;
	vec3 cp = u_relCamPos.xyz;
	cp.y = 0.0;
	vec3 pp = pos;
	pp.y = 0.0;           
	
	float dist = distance(cp, quad_min + pp.xyz);
	float weight = (dist - morph_const.y) / (morph_const.x - morph_const.y);
	
	r.x = dist;
	//return 0.0;
	r.z = clamp(weight, 0.0, 1.0);
	return r;
}


void main()
{

	float m = i_data0.w / 8.0;
	v_wpos = a_position;  
	v_wpos.x *= i_data0.w;
	v_wpos.z *= i_data0.w;
	
	float fraction_x = fract(v_wpos.x / m) * m;
	float fraction_z = fract(v_wpos.z / m) * m;

	vec3 com = computeWeight(v_wpos, i_data0.xyz, i_data1.xy);
	float weight = com.z;
	v_common.x = com.x;
	v_common.y = i_data0.w;
	
	v_wpos.x = v_wpos.x - weight * fraction_x;
	v_wpos.z = v_wpos.z - weight * fraction_z;
	v_wpos += i_data0.xyz;

	vec2 uv = v_wpos.xz / (u_terrainParams.x);
	uv.x += 0.5/u_terrainParams.x;
	uv.y += 0.5/u_terrainParams.x;
	
	v_texcoord1 = uv;

	vec2 size = vec2(1, 0.0);
	float tex_size = 4 * u_terrainParams.y;
	vec3 off = vec3(-1.0 / tex_size, 0.0, 1.0 / tex_size);
    
	float s01 = texture2DLod(u_texHeightmap, uv + off.xy, 0).x;
    float s21 = texture2DLod(u_texHeightmap, uv + off.zy, 0).x;
    float s10 = texture2DLod(u_texHeightmap, uv + off.yx, 0).x;
    float s12 = texture2DLod(u_texHeightmap, uv + off.yz, 0).x;
    vec3 va = normalize(vec3(2, u_terrainScale.y * (s21-s01), 0));
    vec3 vb = normalize(vec3(0, u_terrainScale.y * (s12-s10), 2));
	v_normal = mul(u_terrainMatrix, cross(vb,va) ).xyz;
	
	v_tangent = normalize(cross(v_normal, mul(u_terrainMatrix, vb)));
	v_bitangent = normalize(cross(v_normal, v_tangent));
	
	v_wpos.y = u_terrainScale.y * texture2DLod(u_texHeightmap, uv, 0).x;
	v_wpos.x *= u_terrainScale.x;
	v_wpos.z *= u_terrainScale.z;

	gl_Position = mul(u_viewProj, mul(u_terrainMatrix, vec4(v_wpos, 1.0))); 

	v_texcoord0 = uv * u_terrainParams.x;
    v_wpos = mul(u_terrainMatrix, vec4(v_wpos, 1.0) ).xyz;
	v_view = mul(u_view, vec4(0.0, 0.0, 1.0, 0.0)).xyz;
}
