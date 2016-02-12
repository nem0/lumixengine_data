$input v_wpos, v_view, v_texcoord0, v_texcoord1, v_common, v_common2 // in...

#include "common.sh"

SAMPLER2D(u_texHeightmap, 0);
SAMPLER2D(u_texSplatmap, 1);
SAMPLER2D(u_texSatellitemap, 2);
SAMPLER2D(u_texColormap, 3);
SAMPLER2D(u_texColor, 4);
SAMPLER2D(u_texNormal, 5);
SAMPLER2D(u_texShadowmap, 6);

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_terrainParams;
uniform vec4 u_lightSpecular;
uniform vec4 u_materialColorShininess;
uniform vec4 detail_texture_distance;
uniform vec4 texture_scale;
uniform vec4 u_attenuationParams;
uniform vec4 u_fogParams;
uniform vec4 u_terrainScale;
uniform mat4 u_terrainMatrix;


vec2 getSubtextureUV4(vec2 uv, int z)
{
	static const float o = 1.0/(2.0*2*2);
	static const vec2 origin[4] = {
		vec2(0.0 + o, 0.0 + o),
		vec2(0.5 + o, 0.0 + o),
		vec2(0.0 + o, 0.5 + o),
		vec2(0.5 + o, 0.5 + o)
	};

	return origin[z] + uv / 4.0;
}


vec2 getSubtextureUV9(vec2 uv, int z)
{
	static const float o = 1.0/(3.0*2*2);
	static const vec2 origin[9] = {
		vec2(0.0 + o, 0.0 + o),			vec2(1/3.0 + o, 0.0 + o),		vec2(2/3.0 + o, 0.0 + o),
		vec2(0.0 + o, 1/3.0 + o),		vec2(1/3.0 + o, 1/3.0 + o),		vec2(2/3.0 + o, 1/3.0 + o),
		vec2(0.0 + o, 2/3.0 + o),		vec2(1/3.0 + o, 2/3.0 + o),		vec2(2/3.0 + o, 2/3.0 + o)
	};
	return origin[z] + uv / 6.0;
}


vec2 getSubtextureUV16(vec2 uv, int z)
{
	static const float o = 1.0/(4.0*2*2);
	static const vec2 origin[16] = {
		vec2(0.0, 0.0 + o),			vec2(1/4.0, 0.0 + o),		vec2(2/4.0, 0.0 + o),		vec2(3/4.0, 0.0 + o),
		vec2(0.0, 1/4.0 + o),		vec2(1/4.0, 1/4.0 + o),		vec2(2/4.0, 1/4.0 + o),		vec2(3/4.0, 1/4.0 + o),
		vec2(0.0, 2/4.0 + o),		vec2(1/4.0, 2/4.0 + o),		vec2(2/4.0, 2/4.0 + o),		vec2(3/4.0, 2/4.0 + o),
		vec2(0.0, 3/4.0 + o),		vec2(1/4.0, 3/4.0 + o),		vec2(2/4.0, 3/4.0 + o),		vec2(3/4.0, 3/4.0 + o)
	};
	return origin[z] + uv / 8.0;
}

float mipmapLevel(vec2 uv, vec2 textureSize)
{
    vec2 dx = dFdx(uv * textureSize.x);
    vec2 dy = dFdy(uv * textureSize.y);
    float d = max(dot(dx, dx), dot(dy, dy));
    return 0.5 * log2(d);
}

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
		vec3 va = normalize(vec3(1, (s21-s01) * u_terrainScale.y, 0));
		vec3 vb = normalize(vec3(0, (s12-s10) * u_terrainScale.y, 1));
		vec3 terrain_normal = normalize(mul(u_terrainMatrix, cross(vb,va) ).xyz);
		vec3 terrain_tangent = normalize(cross(terrain_normal, mul(u_terrainMatrix, vb)));
		vec3 terrain_bitangent = normalize(cross(terrain_normal, terrain_tangent));
		
		mat3 tbn = mat3(
			terrain_tangent,
			terrain_normal,
			terrain_bitangent
			);
		tbn = transpose(tbn);

		float splatmap_size = u_terrainParams.w;
		float half_texel = 0.5 / splatmap_size;
		int texture_count = u_terrainParams.z * u_terrainParams.z;
		int detail_size = u_terrainParams.y / (2*u_terrainParams.z);
					
		vec2 ff = fract(detail_uv);

		float u = v_texcoord1.x * splatmap_size - 1.0;
		float v = v_texcoord1.y * splatmap_size - 1.0;
		int x = floor(u);
		int y = floor(v);
		float u_ratio = u - x;
		float v_ratio = v - y;
		float u_opposite = 1 - u_ratio;
		float v_opposite = 1 - v_ratio;
		vec4 splat00 = texture2D(u_texSplatmap, vec2(x/splatmap_size, y/splatmap_size)).rgba;
		vec4 splat01 = texture2D(u_texSplatmap, vec2(x/splatmap_size, (y+1)/splatmap_size)).rgba;
		vec4 splat10 = texture2D(u_texSplatmap, vec2((x+1)/splatmap_size, y/splatmap_size)).rgba;
		vec4 splat11 = texture2D(u_texSplatmap, vec2((x+1)/splatmap_size, (y+1)/splatmap_size)).rgba;
	
		vec2 duv00, duv01, duv10, duv11;
		if(texture_count < 5)
		{
			duv00 = getSubtextureUV4(ff, splat00.x * 256);
			duv01 = getSubtextureUV4(ff, splat01.x * 256);
			duv10 = getSubtextureUV4(ff, splat10.x * 256);
			duv11 = getSubtextureUV4(ff, splat11.x * 256);
		}
		else if(texture_count < 10)
		{
			duv00 = getSubtextureUV9(ff, splat00.x * 256);
			duv01 = getSubtextureUV9(ff, splat01.x * 256);
			duv10 = getSubtextureUV9(ff, splat10.x * 256);
			duv11 = getSubtextureUV9(ff, splat11.x * 256);
		}
		else
		{
			duv00 = getSubtextureUV16(ff, splat00.x * 256);
			duv01 = getSubtextureUV16(ff, splat01.x * 256);
			duv10 = getSubtextureUV16(ff, splat10.x * 256);
			duv11 = getSubtextureUV16(ff, splat11.x * 256);
		}
		
		float mipmap_level = mipmapLevel(v_texcoord0 * texture_scale.x, vec2(detail_size, detail_size));
	
		mipmap_level = min(mipmap_level, log2(detail_size) - 1);
		
		vec4 c00 = texture2DLod(u_texColor, duv00, mipmap_level);
		vec4 c01 = texture2DLod(u_texColor, duv01, mipmap_level);
		vec4 c10 = texture2DLod(u_texColor, duv10, mipmap_level);
		vec4 c11 = texture2DLod(u_texColor, duv11, mipmap_level);

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
			vec4((c00.rgb * b1 + c01.rgb * b2 + c10.rgb * b3 + c11.rgb * b4) / (b1 + b2 + b3 + b4), 1);
		color.rgb *= u_materialColorShininess.rgb;
			
		vec3 wnormal;
		#ifdef NORMAL_MAPPING
			vec4 n00 = texture2DLod(u_texNormal, duv00, mipmap_level);
			vec4 n01 = texture2DLod(u_texNormal, duv01, mipmap_level);
			vec4 n10 = texture2DLod(u_texNormal, duv10, mipmap_level);
			vec4 n11 = texture2DLod(u_texNormal, duv11, mipmap_level);
			wnormal.xz = (n00.xy * b1 + n01.xy * b2 + n10.xy * b3 + n11.xy * b4) / (b1 + b2 + b3 + b4);
			wnormal.xz = wnormal.xz * 2.0 - 1.0;
			wnormal.y = sqrt(1 - dot(wnormal.xz, wnormal.xz));
			wnormal = normalize(mul(tbn, wnormal));
		#else
			wnormal = terrain_normal;
		#endif

		// http://www.gamasutra.com/blogs/AndreyMishkinis/20130716/196339/Advanced_Terrain_Texture_Splatting.php
		// without height blend
		//color = (c00 * u_opposite  + c10  * u_ratio) * v_opposite + (c01 * u_opposite  + c11 * u_ratio) * v_ratio;

		
		float dist = length(v_view);
		float t = (dist - detail_texture_distance.x) / detail_texture_distance.x;
		color = mix(color, texture2D(u_texSatellitemap, v_texcoord1), clamp(t, 0, 1));

		#ifdef DEFERRED
				gl_FragData[0] = color;
				gl_FragData[1].xyz = (wnormal + vec3_splat(1)) * 0.5;
				gl_FragData[1].w = 1;
				float spec = u_materialColorShininess.g / 64.0;
				float shininess = u_materialColorShininess.a / 64.0;
				#ifdef SPECULAR_TEXTURE
					spec *= texture2D(u_texSpecular, v_texcoord0).g;
				#endif
				gl_FragData[2] = vec4(spec, shininess, 0, 1);
		#else
			vec3 view = normalize(v_view);
			vec3 diffuse;
			vec3 texture_specular = 
			#ifdef SPECULAR_TEXTURE
				texture2D(u_texSpecular, v_texcoord0).rgb;
			#else
				vec3(1, 1, 1);
			#endif
			#ifdef POINT_LIGHT
				diffuse = 
				shadePointLight(u_lightDirFov
				, v_wpos
				, wnormal
				, view
				, detail_uv.xy
				, u_lightPosRadius
				, u_lightRgbAttenuation
				, u_materialColorShininess
				, u_lightSpecular
				, texture_specular
				);
				
				diffuse = diffuse.xyz * color.rgb;
				#ifdef HAS_SHADOWMAP
					diffuse = diffuse * pointLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0), u_lightDirFov.w); 
				#endif
			#else
				diffuse = shadeDirectionalLight(u_lightDirFov.xyz
					, view
					, u_lightRgbAttenuation.rgb
					, u_lightSpecular.rgb
					, wnormal
					, u_materialColorShininess
					, texture_specular);
				diffuse = diffuse.xyz * color.rgb;
				float ndotl = -dot(terrain_normal, u_lightDirFov.xyz);
				diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0), ndotl); 	
			#endif

			
			#ifdef MAIN
				vec3 ambient = u_ambientColor.rgb * color.rgb;
			#else
				vec3 ambient = vec3(0, 0, 0);
			#endif  

			vec4 view_pos = mul(u_view, vec4(v_wpos, 1.0));
			float fog_factor = getFogFactor(view_pos.z / view_pos.w, u_fogColorDensity.w, v_wpos.y, u_fogParams);

			#ifdef POINT_LIGHT
				gl_FragColor.xyz = (1 - fog_factor) * (diffuse + ambient);
			#else
				gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
			#endif
			gl_FragColor.w = 1.0;
		#endif
	#endif // else SHADOW
}
