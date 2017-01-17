$input v_wpos, v_view, v_texcoord0, v_texcoord1, v_common, v_common2 // in...

#include "common.sh"

SAMPLER2D(u_texHeightmap, 0);
SAMPLER2D(u_texSplatmap, 1);
SAMPLER2D(u_texSatellitemap, 2);
SAMPLER2D(u_texColormap, 3);
SAMPLER2DARRAY(u_texColor, 4);
SAMPLER2DARRAY(u_texNormal, 5);


uniform vec4 u_terrainParams;
uniform vec4 u_materialColor;
uniform vec4 detail_texture_distance;
uniform vec4 texture_scale;
uniform vec4 u_terrainScale;
uniform mat4 u_terrainMatrix;
uniform vec4 u_roughnessMetallic;


void main()
{
	#ifdef SHADOW
		float depth = v_common2.z/v_common2.w;
		gl_FragColor = vec4_splat(depth);
	#else
		vec2 detail_uv = v_texcoord0.xy * texture_scale.x;

		vec2 uv = v_texcoord1;
		float tex_size = u_terrainParams.x;
		vec3 off = vec3(-0.5 / tex_size, 0.0, 0.5 / tex_size);
		
		float s01 = texture2D(u_texHeightmap, uv + off.xy).x;
		float s21 = texture2D(u_texHeightmap, uv + off.zy).x;
		float s10 = texture2D(u_texHeightmap, uv + off.yx).x;
		float s12 = texture2D(u_texHeightmap, uv + off.yz).x;
		vec3 va = normalize(vec3(1.0, (s21-s01) * u_terrainScale.y, 0.0));
		vec3 vb = normalize(vec3(0.0, (s12-s10) * u_terrainScale.y, 1.0));
		#if BGFX_SHADER_LANGUAGE_HLSL
			mat3 terrain_matrix3 = (mat3)(u_terrainMatrix);
		#else
			mat3 terrain_matrix3 = mat3(u_terrainMatrix);
		#endif
		vec3 terrain_normal = normalize(mul(terrain_matrix3, cross(vb,va) ));
		vec3 terrain_tangent = normalize(cross(terrain_normal, mul(terrain_matrix3, vb)));
		vec3 terrain_bitangent = normalize(cross(terrain_normal, terrain_tangent));
		
		mat3 tbn = mat3(
			terrain_tangent,
			terrain_normal,
			terrain_bitangent
			);
		tbn = transpose(tbn);

		float splatmap_size = u_terrainParams.z;
		float half_texel = 0.5 / splatmap_size;
					
		float u = v_texcoord1.x * splatmap_size - 1.0;
		float v = v_texcoord1.y * splatmap_size - 1.0;
		float x = floor(u);
		float y = floor(v);
		float u_ratio = u - x;
		float v_ratio = v - y;
		float u_opposite = 1.0 - u_ratio;
		float v_opposite = 1.0 - v_ratio;
		vec4 splat00 = texture2D(u_texSplatmap, vec2(x/splatmap_size, y/splatmap_size)).rgba;
		vec4 splat01 = texture2D(u_texSplatmap, vec2(x/splatmap_size, (y+1.0)/splatmap_size)).rgba;
		vec4 splat10 = texture2D(u_texSplatmap, vec2((x+1.0)/splatmap_size, y/splatmap_size)).rgba;
		vec4 splat11 = texture2D(u_texSplatmap, vec2((x+1.0)/splatmap_size, (y+1.0)/splatmap_size)).rgba;
	
		vec4 c00 = texture2DArray(u_texColor, vec3(detail_uv, splat00.x * 256.0));
		vec4 c01 = texture2DArray(u_texColor, vec3(detail_uv, splat01.x * 256.0));
		vec4 c10 = texture2DArray(u_texColor, vec3(detail_uv, splat10.x * 256.0));
		vec4 c11 = texture2DArray(u_texColor, vec3(detail_uv, splat11.x * 256.0));

		vec4 bicoef = vec4(
			u_opposite * v_opposite,
			u_opposite * v_ratio,
			u_ratio * v_opposite,
			u_ratio * v_ratio
		);
			
		float a00 = (splat00.y * c00.a) * bicoef.x;
		float a01 = (splat01.y * c01.a) * bicoef.y;
		float a10 = (splat10.y * c10.a) * bicoef.z;
		float a11 = (splat11.y * c11.a) * bicoef.w;

		float ma = max(a00, a01);
		ma = max(ma, a10);
		ma = max(ma, a11); 
		ma = ma * 0.5;
		
		float b1 = max(a00 - ma, 0);
		float b2 = max(a01 - ma, 0);
		float b3 = max(a10 - ma, 0);
		float b4 = max(a11 - ma, 0);
		
		vec4 color = 
			texture2D(u_texColormap, v_texcoord1) * 
			vec4((c00.rgb * b1 + c01.rgb * b2 + c10.rgb * b3 + c11.rgb * b4) / (b1 + b2 + b3 + b4), 1.0);
		color.rgb *= u_materialColor.rgb;
			
		vec3 wnormal;
		#ifdef NORMAL_MAPPING
			vec4 n00 = texture2DArray(u_texNormal, vec3(detail_uv, splat00.x * 256.0));
			vec4 n01 = texture2DArray(u_texNormal, vec3(detail_uv, splat01.x * 256.0));
			vec4 n10 = texture2DArray(u_texNormal, vec3(detail_uv, splat10.x * 256.0));
			vec4 n11 = texture2DArray(u_texNormal, vec3(detail_uv, splat11.x * 256.0));
			wnormal.xzy = (n00.xyz * b1 + n01.xyz * b2 + n10.xyz * b3 + n11.xyz * b4) / (b1 + b2 + b3 + b4);
			wnormal = wnormal * 2.0 - 1.0;
			wnormal = normalize(mul(tbn, wnormal));
		#else
			wnormal = terrain_normal;
		#endif

		// http://www.gamasutra.com/blogs/AndreyMishkinis/20130716/196339/Advanced_Terrain_Texture_Splatting.php
		// without height blend
		//color = (c00 * u_opposite  + c10  * u_ratio) * v_opposite + (c01 * u_opposite  + c11 * u_ratio) * v_ratio;
		
		float dist = length(v_view);
		float t = (dist - detail_texture_distance.x) / detail_texture_distance.x;
		color = mix(color, texture2D(u_texSatellitemap, v_texcoord1), clamp(t, 0.0, 1.0));
		wnormal = mix(wnormal, terrain_normal, clamp(t, 0.0, 1.0));

		gl_FragData[0].rgb = color.rgb;
		gl_FragData[0].w = u_roughnessMetallic.x;
		gl_FragData[1].xyz = (wnormal + vec3_splat(1.0)) * 0.5;
		gl_FragData[1].w = u_roughnessMetallic.y;
		gl_FragData[2] = vec4(1, 0, 0.0, 1.0);
		
	#endif // else SHADOW
}
