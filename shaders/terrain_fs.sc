$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_texcoord1, v_common // in...

#include "common.sh"

SAMPLER2D(u_texHeightmap, 0);
SAMPLER2D(u_texSplatmap, 1);
SAMPLER2D(u_texSatellitemap, 2);
SAMPLER2D(u_texColormap, 3);
SAMPLER3D(u_texColor, 4);
SAMPLER3D(u_texNormal, 5);
SAMPLER2D(u_texShadowmap, 6);

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbInnerR;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_terrainParams;
uniform vec4 u_lightSpecular;
uniform vec4 u_materialSpecularShininess;
uniform vec4 detail_texture_distance;
uniform vec4 texture_scale;
uniform vec4 u_attenuationParams;


vec3 calcLight(vec4 dirFov, vec3 _wpos, vec3 _normal, vec3 _view, vec2 uv)
{
	vec3 lp = u_lightPosRadius.xyz - _wpos;
	float dist = length(lp);
	float attn = 1.0 / (u_attenuationParams.x + u_attenuationParams.y * dist + u_attenuationParams.z * dist * dist);
	attn = attn;
	
	vec3 toLightDir = normalize(lp);
	if(dirFov.w < 3.14159)
	{
		float cosDir = dot(normalize(dirFov.xyz), normalize(-toLightDir));
		float cosCone = cos(dirFov.w * 0.5);
	
		if(cosDir < cosCone)
			discard;
		attn *= (cosDir - cosCone) / (1 - cosCone);
	}
	
	vec2 bln = blinn(toLightDir, _normal, _view);
	vec4 lc = lit(bln.x, bln.y, u_materialSpecularShininess.w);
	vec3 rgb = 
		attn * (u_lightRgbInnerR.xyz * saturate(lc.y) 
		+ u_lightSpecular.xyz * u_materialSpecularShininess.xyz *
		#ifdef SPECULAR_TEXTURE
			texture2D(u_texSpecular, uv).rgb * 
		#endif
		saturate(lc.z));
	return rgb;
}


float VSM(sampler2D depths, vec2 uv, float compare)
{
	return smoothstep(compare-0.0001, compare, texture2D(depths, uv).x * 0.5 + 0.5);
}


float getShadowmapValue(vec4 position)
{
	vec3 shadow_coord[4];
	shadow_coord[0] = mul(u_shadowmapMatrices[0], position).xyz;
	shadow_coord[1] = mul(u_shadowmapMatrices[1], position).xyz;
	shadow_coord[2] = mul(u_shadowmapMatrices[2], position).xyz;
	shadow_coord[3] = mul(u_shadowmapMatrices[3], position).xyz;

	vec2 tt[4];
	tt[0] = vec2(shadow_coord[0].x * 0.5, shadow_coord[0].y * 0.5);
	tt[1] = vec2(0.5 + shadow_coord[1].x * 0.5, shadow_coord[1].y * 0.5);
	tt[2] = vec2(shadow_coord[2].x * 0.5, 0.5 + shadow_coord[2].y * 0.5);
	tt[3] = vec2(0.5 + shadow_coord[3].x * 0.5, 0.5 + shadow_coord[3].y * 0.5);

	int split_index = 3;
	if(step(shadow_coord[0].x, 0.99) * step(shadow_coord[0].y, 0.99)
		* step(0.01, shadow_coord[0].x)	* step(0.01, shadow_coord[0].y) > 0.0)
		split_index = 0;
	else if(step(shadow_coord[1].x, 0.99) * step(shadow_coord[1].y, 0.99)
		* step(0.01, shadow_coord[1].x)	* step(0.01, shadow_coord[1].y) > 0.0)
		split_index = 1;
	else if(step(shadow_coord[2].x, 0.99) * step(shadow_coord[2].y, 0.99)
		* step(0.01, shadow_coord[2].x)	* step(0.01, shadow_coord[2].y) > 0.0)
		split_index = 2;
	else if(step(shadow_coord[3].x, 0.99) * step(shadow_coord[3].y, 0.99)
		* step(0.01, shadow_coord[3].x)	* step(0.01, shadow_coord[3].y) > 0.0)
		split_index = 3;
	else
		return 1.0;

	return step(shadow_coord[split_index].z, 1) * VSM(u_texShadowmap, tt[split_index], shadow_coord[split_index].z);
}



float getPLShadowmapValue(vec4 position, float fov)
{
	if(fov > 3.15159)
	{
		vec4 a = mul(u_shadowmapMatrices[0], position);
		vec4 b = mul(u_shadowmapMatrices[1], position);
		vec4 c = mul(u_shadowmapMatrices[2], position);
		vec4 d = mul(u_shadowmapMatrices[3], position);
		
		a = a / a.w;
		b = b / b.w;
		c = c / c.w;
		d = d / d.w;

		float l0 = length(a.xy - vec2_splat(0.5));
		float l1 = length(b.xy - vec2_splat(0.5));
		float l2 = length(c.xy - vec2_splat(0.5));
		float l3 = length(d.xy - vec2_splat(0.5));
		
		float m = min(min(l0, l1), min(l2, l3));
		
		bool selection0 = all(lessThan(a.xy, vec2_splat(0.99))) && all(greaterThan(a.xy, vec2_splat(0.01))) && a.z < 1;
		bool selection1 = all(lessThan(b.xy, vec2_splat(0.99))) && all(greaterThan(b.xy, vec2_splat(0.01))) && b.z < 1;
		bool selection2 = all(lessThan(c.xy, vec2_splat(0.99))) && all(greaterThan(c.xy, vec2_splat(0.01))) && c.z < 1;
		bool selection3 = all(lessThan(d.xy, vec2_splat(0.99))) && all(greaterThan(d.xy, vec2_splat(0.01))) && d.z < 1;
		

		if(selection0)
			return step(a.z, 1) * VSM(u_texShadowmap, vec2(a.x*0.5, a.y*0.5), a.z);
			//gl_FragColor = texture2D(u_texShadowmap, vec2(a.x*0.5, a.y*0.5));
		else if(selection1)
			return step(b.z, 1) * VSM(u_texShadowmap, vec2(0.5+b.x*0.5, b.y*0.5), b.z);
			//gl_FragColor = texture2D(u_texShadowmap, vec2(0.5+b.x*0.5, b.y*0.5));
		else if(selection2)
			return step(c.z, 1) * VSM(u_texShadowmap, vec2(c.x*0.5, 0.5+c.y*0.5), c.z);
			//gl_FragColor = texture2D(u_texShadowmap, vec2(c.x*0.5, 0.5+c.y*0.5));
		else 
			return step(d.z, 1) * VSM(u_texShadowmap, vec2(0.5+d.x*0.5, 0.5+d.y*0.5), d.z);
			//gl_FragColor = texture2D(u_texShadowmap, vec2(0.5+d.x*0.5, 0.5+d.y*0.5));
	}
	else
	{
		vec4 tmp = mul(u_shadowmapMatrices[0], position);
		vec3 shadow_coord = tmp.xyz / tmp.w;
		return step(shadow_coord.z, 1) * VSM(u_texShadowmap, shadow_coord.xy, shadow_coord.z);
	}
}



void main()
{
	vec2 detail_uv = v_texcoord0.xy * texture_scale.x;

	mat3 tbn = mat3(
				normalize(v_tangent),
				normalize(v_normal),
				normalize(v_bitangent)
				);
	tbn = transpose(tbn);

	float tex_size = 4 * u_terrainParams.y;
	float texel = 1/tex_size;
	float half_texel = texel * 0.5;
	int texture_count = u_terrainParams.z;
				
    vec4 splat = texture2D(u_texSplatmap, v_texcoord1 - vec2(half_texel, half_texel)).rgba;
	vec2 ff = fract(detail_uv);

	vec4 color = 
		texture3D(u_texColor, vec3(detail_uv.xy, splat.x *256.0 / texture_count));

	float u = v_texcoord1.x * tex_size - 1.0;
	float v = v_texcoord1.y * tex_size - 1.0;
	int x = floor(u);
	int y = floor(v);
	float u_ratio = u - x;
	float v_ratio = v - y;
	float u_opposite = 1 - u_ratio;
	float v_opposite = 1 - v_ratio;
	vec4 splat00 = texture2D(u_texSplatmap, vec2(x/tex_size, y/tex_size)).rgba;
	vec4 splat01 = texture2D(u_texSplatmap, vec2(x/tex_size, (y+1)/tex_size)).rgba;
	vec4 splat10 = texture2D(u_texSplatmap, vec2((x+1)/tex_size, y/tex_size)).rgba;
	vec4 splat11 = texture2D(u_texSplatmap, vec2((x+1)/tex_size, (y+1)/tex_size)).rgba;
	vec4 c00 = texture3D(u_texColor, vec3(detail_uv.xy, splat00.x * 256.0 / texture_count));
	vec4 c01 = texture3D(u_texColor, vec3(detail_uv.xy, splat01.x * 256.0 / texture_count));
	vec4 c10 = texture3D(u_texColor, vec3(detail_uv.xy, splat10.x * 256.0 / texture_count));
	vec4 c11 = texture3D(u_texColor, vec3(detail_uv.xy, splat11.x * 256.0 / texture_count));

	vec4 bicoef = vec4(
		u_opposite * v_opposite,
		u_opposite * v_ratio,
		u_ratio * v_opposite,
		u_ratio * v_ratio
	);
		
	float a00 = (splat00.y + c00.a) * bicoef.x;
	float a01 = (splat01.y + c01.a) * bicoef.y;
	float a10 = (splat10.y + c10.a) * bicoef.z;
	float a11 = (splat11.y + c11.a) * bicoef.w;

	float ma = max(a00, a01);
	ma = max(ma, a10);
	ma = max(ma, a11);
	ma = ma - 0.05;
	
    float b1 = max(a00 - ma, 0);
    float b2 = max(a01 - ma, 0);
    float b3 = max(a10 - ma, 0);
    float b4 = max(a11 - ma, 0);

    color = 
		texture2D(u_texColormap, v_texcoord1) * 
		vec4((c00.rgb * b1 + c01.rgb * b2 + c10.rgb * b3 + c11.rgb * b4) / (b1 + b2 + b3 + b4), 1);

	vec3 normal;
	#ifdef NORMAL_MAPPING
		vec4 n00 = texture3D(u_texNormal, vec3(detail_uv.xy, splat00.x * 256.0 / texture_count));
		vec4 n01 = texture3D(u_texNormal, vec3(detail_uv.xy, splat01.x * 256.0 / texture_count));
		vec4 n10 = texture3D(u_texNormal, vec3(detail_uv.xy, splat10.x * 256.0 / texture_count));
		vec4 n11 = texture3D(u_texNormal, vec3(detail_uv.xy, splat11.x * 256.0 / texture_count));
		normal.xz = (n00.xy * b1 + n01.xy * b2 + n10.xy * b3 + n11.xy * b4) / (b1 + b2 + b3 + b4);
		normal.xz = normal.xz * 2.0 - 1.0;
		normal.y = sqrt(1 - dot(normal.xz, normal.xz));
	#else
		normal = vec3(0.0, 1.0, 0.0);
	#endif
		
//	gl_FragColor = vec4(xx.z, 0, 0, 1);
//	return;
	
	// http://www.gamasutra.com/blogs/AndreyMishkinis/20130716/196339/Advanced_Terrain_Texture_Splatting.php
	// without height blend
	//color = (c00 * u_opposite  + c10  * u_ratio) * v_opposite + (c01 * u_opposite  + c11 * u_ratio) * v_ratio;
		
	vec3 view = normalize(v_view);
	
	float t = (v_common.x - detail_texture_distance.x) / detail_texture_distance.x;
	color = mix(color, texture2D(u_texSatellitemap, v_texcoord1), clamp(t, 0, 1));
				 
	vec3 diffuse;
	#ifdef POINT_LIGHT
		diffuse = calcLight(u_lightDirFov, v_wpos, mul(tbn, normal), view, detail_uv.xy);
		diffuse = diffuse.xyz * color.rgb;
		#ifdef HAS_SHADOWMAP
			diffuse = diffuse * getPLShadowmapValue(vec4(v_wpos, 1.0), u_lightDirFov.w); 
		#endif
	#else
		diffuse = calcGlobalLight(u_lightDirFov.xyz, u_lightRgbInnerR.rgb, mul(tbn, normal));
		diffuse = diffuse.xyz * color.rgb;
		diffuse = diffuse * getShadowmapValue(vec4(v_wpos, 1.0)); 
	#endif

	#ifdef MAIN
		vec3 ambient = u_ambientColor.rgb * color.rgb;
	#else
		vec3 ambient = vec3(0, 0, 0);
	#endif  

    vec4 view_pos = mul(u_view, vec4(v_wpos, 1.0));
    float fog_factor = getFogFactor(view_pos.z / view_pos.w, u_fogColorDensity.w);
	fog_factor = fog_factor * clamp((7.0 - v_wpos.y) / 10, 0, 1);
	
	#ifdef POINT_LIGHT
		gl_FragColor.xyz = (1 - fog_factor) * (diffuse + ambient);
	#else
		gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
	#endif
	gl_FragColor.w = 1.0;
}
