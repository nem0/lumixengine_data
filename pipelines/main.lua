local DEFAULT_RENDER_MASK = getLayerMask(this, "default")
local TRANSPARENT_RENDER_MASK = getLayerMask(this, "transparent")
local TERRAIN_RENDER_MASK = getLayerMask(this, "terrain")
local GRASS_RENDER_MASK = getLayerMask(this, "grass")
local WATER_RENDER_MASK = getLayerMask(this, "water")
local FUR_RENDER_MASK = getLayerMask(this, "fur")
local OCCLUDER_MASK = getLayerMask(this, "occluder")
local NOSHADOWS_RENDER_MASK = getLayerMask(this, "no_shadows")
local ALL_RENDER_MASK = DEFAULT_RENDER_MASK + TRANSPARENT_RENDER_MASK + WATER_RENDER_MASK + FUR_RENDER_MASK + NOSHADOWS_RENDER_MASK + TERRAIN_RENDER_MASK + GRASS_RENDER_MASK
local LUA_SCRIPT_TYPE = Engine.getComponentType("lua_script")
local SHADOWMAP_SIZE = 1024

local exposure = 4
local screenshot_request = 0
local occlusion_culling_enabled = false
local particles_enabled = true
local render_gizmos = true
local render_shadowmap_debug = false
local render_shadowmap_debug_fullsize = false
local render_shadowmap = true
local blur_shadowmap = true
local disable_render = false
local render_fur = true
local render_debug_deferred = 
{ 
 { label = "Albedo", enabled = false, fullscreen = false, mask = {1, 1, 1, 0}, g_buffer_idx = 0},
 { label = "Normal", enabled = false, fullscreen = false, mask = {1, 1, 1, 0}, g_buffer_idx = 1},
 { label = "Roughness", enabled = false, fullscreen = false, mask = {0, 0, 0, 1}, g_buffer_idx = 0},
 { label = "Metallic", enabled = false, fullscreen = false, mask = {0, 0, 0, 1}, g_buffer_idx = 1},
 { label = "AO", enabled = false, fullscreen = false, mask = {1, 1, 1, 0}, g_buffer_idx = 2},
 { label = "Depth", enabled = false, fullscreen = false, mask = {1, 0, 0, 0}, g_buffer_idx = 3},
}

function getCameraSlot()
	if RENDER_TEST then
		return "editor"
	elseif PROBE then
		return "probe"
	elseif APP then
		return "main"
	elseif GAME_VIEW  then
		return "main"
	else
		return "editor"
	end
end

function doPostprocess(pipeline, this_env, slot, camera_slot)
	local scene_renderer = Renderer.getPipelineScene(pipeline)
	local universe = Engine.getSceneUniverse(scene_renderer)
	local scene_lua_script = Engine.getScene(universe, "lua_script")
	local camera_entity = Renderer.getCameraInSlot(scene_renderer, camera_slot)
	if camera_entity < 0 then return end
	if not Engine.hasComponent(universe, camera_entity, LUA_SCRIPT_TYPE) then return end
	local script_count = LuaScript.getScriptCount(scene_lua_script, camera_entity)
	for i = 1, script_count do
		local env = LuaScript.getEnvironment(scene_lua_script, camera_entity, i - 1)
		if env ~= nil then 
			if env._IS_POSTPROCESS_INITIALIZED == nil and env.initPostprocess ~= nil then
				env.initPostprocess(pipeline, this_env)
				env._IS_POSTPROCESS_INITIALIZED = true
			end
			if env.postprocess ~= nil and (env._postprocess_slot == slot or (env._postprocess_slot == nil and slot == "main"))  then
				env.postprocess(pipeline, this_env, slot)
			end
		end
	end
end

function createFramebuffers()

	addFramebuffer(this, "linear", {
		width = 1024,
		height = 1024,
		size_ratio = {1, 1},
		renderbuffers = {
			{ format = "rgba8" },
			{ format = "depth24stencil8" }
		}
	})

	addFramebuffer(this, "lum256", {
		width = 256,
		height = 256,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(this,  "lum64", {
		width = 64,
		height = 64,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(this,  "lum16", {
		width = 16,
		height = 16,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(this,  "lum4", {
		width = 4,
		height = 4,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(this,  "lum1a", {
		width = 1,
		height = 1,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(this,  "lum1b", {
		width = 1,
		height = 1,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(this,  "hdr", {
		width = 1024,
		height = 1024,
		screen_size = true,
		renderbuffers = {
			{ format = "rgba16f" },
			{ format = "depth24stencil8" }
		}
	})

	if not APP and not RENDER_TEST then
		addFramebuffer(this, "default", {
			width = 1024,
			height = 1024,
			renderbuffers = {
				{ format = "rgba8" },
				{ format = "depth24stencil8" }
			}
		})
	end
		
	if SCENE_VIEW then
		addFramebuffer(this, "selection_mask", {
			width = 1024,
			height = 1024,
			size_ratio = {1, 1},
			renderbuffers = {
				{ format = "r32f" }
			}
		})
	end
		
	addFramebuffer(this, "g_buffer", {
		width = 1024,
		height = 1024,
		screen_size = true,
		renderbuffers = {
			{ format = "rgba8" },
			{ format = "rgba16f" },
			{ format = "rgba8" },
			{ format = "depth24stencil8" }
		}
	})
	
	addFramebuffer(this, "shadowmap_blur", {
		width = SHADOWMAP_SIZE,
		height = SHADOWMAP_SIZE,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(this, "shadowmap", {
		width = SHADOWMAP_SIZE,
		height = SHADOWMAP_SIZE,
		renderbuffers = {
			{format="r32f" },
			{format = "depth24"}
		}
	})

	addFramebuffer(this, "point_light_shadowmap", {
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth24"}
		}
	})

	addFramebuffer(this, "point_light2_shadowmap", {
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth24"}
		}
	})
end

function loadResources(ctx)
	ctx.screen_space_material = Engine.loadResource(g_engine, "pipelines/screenspace/screenspace.mat", "material")
	ctx.screen_space_debug_material = Engine.loadResource(g_engine, "pipelines/screenspace/screenspace_debug.mat", "material")
	ctx.blur_material = Engine.loadResource(g_engine, "pipelines/common/blur.mat", "material")
	ctx.pbr_material = Engine.loadResource(g_engine, "pipelines/pbr/pbr.mat", "material")
	ctx.pbr_local_light_material = Engine.loadResource(g_engine, "pipelines/pbr/pbrlocallight.mat", "material")
	ctx.tonemap_material = Engine.loadResource(g_engine, "pipelines/tonemap/tonemap.mat", "material")
	ctx.extract_luminance_material = Engine.loadResource(g_engine, "pipelines/tonemap/extractluminance.mat", "material")
	ctx.selection_outline_material = Engine.loadResource(g_engine, "pipelines/common/selection_outline.mat", "material")
end

function initUniforms(ctx)
	ctx.exposure_uniform = createVec4ArrayUniform(this, "u_exposure", 1)
	ctx.multiplier_uniform = createVec4ArrayUniform(this, "u_multiplier", 1)
	ctx.texture_uniform = createUniform(this, "u_texture")
	ctx.gbuffer0_uniform = createUniform(this, "u_gbuffer0")
	ctx.gbuffer1_uniform = createUniform(this, "u_gbuffer1")
	ctx.gbuffer2_uniform = createUniform(this, "u_gbuffer2")
	ctx.gbuffer_depth_uniform = createUniform(this, "u_gbuffer_depth")
	ctx.irradiance_map_uniform = createUniform(this, "u_irradiance_map")
	ctx.radiance_map_uniform = createUniform(this, "u_radiance_map")
	ctx.lum_size_uniform = createVec4ArrayUniform(this, "u_offset", 16)
	ctx.hdr_buffer_uniform = createUniform(this, "u_hdrBuffer")
	ctx.avg_luminance_uniform = createUniform(this, "u_avgLuminance")
	ctx.depth_buffer_uniform = createUniform(this, "u_depthBuffer")
	ctx.shadowmap_uniform = createUniform(this, "u_texShadowmap")

	
	ctx.lum_uniforms = {}
	local sizes = {256, 64, 16, 4, 1 }
	for key,value in ipairs(sizes) do
		lum_uniforms[value] = {}
		for j = 0,1 do
			for i = 0,1 do
				local x = 1 / (4 * value) + i / (2 * value) - 1 / (2 * value)
				local y = 1 / (4 * value) + j / (2 * value) - 1 / (2 * value)
				ctx.lum_uniforms[value][1 + i + j * 2] = {x, y, 0, 0}
			end
		end
	end
end

function init(ctx)
	createFramebuffers()
	loadResources(ctx)
	initUniforms(ctx)
end
init(_ENV)

function rigid(camera_slot)

	newView(this, "geometry_pass_terrain", "g_buffer", TERRAIN_RENDER_MASK)
		setPass(this, "DEFERRED")
		applyCamera(this, camera_slot)
		clear(this, CLEAR_ALL, 0x00000000)
		
		setStencil(this, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(this, 0xff)
		setStencilRef(this, 1)

	newView(this, "geometry_pass", "g_buffer", DEFAULT_RENDER_MASK + NOSHADOWS_RENDER_MASK)
		setPass(this, "DEFERRED")
		applyCamera(this, camera_slot)
		
		setStencil(this, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(this, 0xff)
		setStencilRef(this, 1)
	
	newView(this, "geometry_pass_grass", "g_buffer", GRASS_RENDER_MASK)
		setPass(this, "DEFERRED")
		applyCamera(this, camera_slot)
		
		setStencil(this, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(this, 0xff)
		setStencilRef(this, 1)

	newView(this, "clear_main", "hdr")
		-- there are strange artifacts on some platforms without this clear
		clear(this, CLEAR_ALL, 0x00000000)
	
	newView(this, "copyRenderbuffer", "hdr");
		copyRenderbuffer(this, "g_buffer", 3, "hdr", 1)

	newView(this, "decals", "g_buffer")
		setPass(this, "DEFERRED")
		disableDepthWrite(this)
		applyCamera(this, camera_slot)
		bindFramebufferTexture(this, "hdr", 1, gbuffer_depth_uniform)
		renderDecalsVolumes(this)
		
	newView(this, "light_pass", "hdr")
		setPass(this, "MAIN")
		applyCamera(this, camera_slot)
		clear(this, CLEAR_COLOR, 0x00000000)
		
		disableDepthWrite(this)
		setActiveGlobalLightUniforms(this)
		bindFramebufferTexture(this, "g_buffer", 0, gbuffer0_uniform)
		bindFramebufferTexture(this, "g_buffer", 1, gbuffer1_uniform)
		bindFramebufferTexture(this, "g_buffer", 2, gbuffer2_uniform)
		bindFramebufferTexture(this, "g_buffer", 3, gbuffer_depth_uniform)
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
		drawQuad(this, 0, 0, 1, 1, pbr_material)
		
	newView(this, "local_light_pass", "hdr")
		setPass(this, "MAIN")
		disableDepthWrite(this)
		enableBlending(this, "add")
		applyCamera(this, camera_slot)
		bindFramebufferTexture(this, "g_buffer", 0, gbuffer0_uniform)
		bindFramebufferTexture(this, "g_buffer", 1, gbuffer1_uniform)
		bindFramebufferTexture(this, "g_buffer", 2, gbuffer2_uniform)
		bindFramebufferTexture(this, "g_buffer", 3, gbuffer_depth_uniform)
		renderLightVolumes(this, pbr_local_light_material)
		disableBlending(this)

	newView(this, "deferred_debug_shapes", "hdr")
		setPass(this, "EDITOR")
		applyCamera(this, camera_slot)
		setStencil(this, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(this, 0xff)
		setStencilRef(this, 1)
		renderDebugShapes(this)	
	
end

local current_lum1 = "lum1a"


function extractLuminance()
	newView(this, "hdr_luminance", "lum256")
		setPass(this, "HDR_EXTRACT_LUMINANCE")
		disableDepthWrite(this)
		disableBlending(this)
		setUniform(this, lum_size_uniform, lum_uniforms[256])
		bindFramebufferTexture(this, "hdr", 0, hdr_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
		drawQuad(this, 0, 0, 1, 1, extract_luminance_material)
	
	newView(this, "lum64", "lum64")
		setPass(this, "MAIN")
		setUniform(this, lum_size_uniform, lum_uniforms[64])
		bindFramebufferTexture(this, "lum256", 0, hdr_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
		drawQuad(this, 0, 0, 1, 1, extract_luminance_material)

	newView(this, "lum16", "lum16")
		setPass(this, "MAIN")
		setUniform(this, lum_size_uniform, lum_uniforms[16])
		bindFramebufferTexture(this, "lum64", 0, hdr_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
		drawQuad(this, 0, 0, 1, 1, extract_luminance_material)
	
	newView(this, "lum4", "lum4")
		setPass(this, "MAIN")
		setUniform(this, lum_size_uniform, lum_uniforms[4])
		bindFramebufferTexture(this, "lum16", 0, hdr_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
		drawQuad(this, 0, 0, 1, 1, extract_luminance_material)

	local old_lum1 = "lum1b"
	if current_lum1 == "lum1a" then 
		current_lum1 = "lum1b" 
		old_lum1 = "lum1a"
	else 
		current_lum1 = "lum1a" 
	end

	newView(this, "lum1", current_lum1)
		setPass(this, "FINAL")
		setUniform(this, lum_size_uniform, lum_uniforms[1])
		bindFramebufferTexture(this, "lum4", 0, hdr_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
		bindFramebufferTexture(this, old_lum1, 0, avg_luminance_uniform)
		drawQuad(this, 0, 0, 1, 1, extract_luminance_material)
end

function tonemapping()
	extractLuminance()
	
	newView(this, "tonemap", "linear")
		setMaterialDefine(this, tonemap_material, "FIXED_EXPOSURE", APP == nil and GAME_VIEW == nil)
		setPass(this, "MAIN")
		clear(this, CLEAR_DEPTH, 0x303030ff)
		setUniform(this, exposure_uniform, {{exposure, 0, 0, 0}})
		bindFramebufferTexture(this, "hdr", 0, texture_uniform)
		bindFramebufferTexture(this, current_lum1, 0, avg_luminance_uniform)
		drawQuad(this, 0, 0, 1, 1, tonemap_material)
end

function renderSelectionOutline(ctx, camera_slot)
	newView(this, "selection_mask", "selection_mask", ALL_RENDER_MASK)
		clear(this, CLEAR_COLOR, 0xffffffff)
		setPass(this, "SHADOW")
		disableDepthWrite(this)
		applyCamera(this, camera_slot)
		renderSelection(this)

	newView(this, "selection_outline", "default")
		setPass(this, "MAIN")
		disableDepthWrite(this)
		bindFramebufferTexture(this, "selection_mask", 0, texture_uniform)
		drawQuad(this, 0, 0, 1, 1, selection_outline_material)

end

function renderEditorIcons(camera_slot)
	if render_gizmos then
		newView(this, "editor", "default", 0xFFFFffffFFFFffff)
			bindFramebufferTexture(this, "g_buffer", 3, depth_buffer_uniform)
			setPass(this, "EDITOR")
			enableDepthWrite(this)
			enableBlending(this, "alpha")
			applyCamera(this, camera_slot)
			renderIcons(this)
	end
end

function renderGizmo(camera_slot)
	if render_gizmos then
		newView(this, "gizmo", "default")
			setPass(this, "EDITOR")
			enableBlending(this, "alpha")
			applyCamera(this, camera_slot)
			renderGizmos(this)
	end
end


function shadowmapDebug(ctx, x, y)
	if render_shadowmap_debug then
		newView(this, "shadowmap_debug", "default")
			setPass(this, "MAIN")
			bindFramebufferTexture(this, "shadowmap", 0, texture_uniform)
			drawQuad(this, 0.01, 0.01, 0.23, 0.23, screen_space_material)
	end
	if render_shadowmap_debug_fullsize then
		newView(this, "shadowmap_debug_fullsize", "default")
			setPass(this, "MAIN", "default")
			bindFramebufferTexture(this, "shadowmap", 0, texture_uniform)
			drawQuad(this, 0, 0, 1, 1, screen_space_material)
	end
end

function renderDebug()
	local offset_x = 0
	local offset_y = 0
	for i, _ in ipairs(render_debug_deferred) do
		if render_debug_deferred[i].enabled then
			newView(this, "deferred_debug_"..tostring(i), "default")
				setPass(this, "MAIN")
				bindFramebufferTexture(this, "g_buffer", render_debug_deferred[i].g_buffer_idx, texture_uniform)
				setUniform(this, multiplier_uniform, {render_debug_deferred[i].mask})
				drawQuad(this, 0.01 + offset_x, 0.01 + offset_y, 0.23, 0.23, screen_space_debug_material)
				
			offset_x = offset_x + 0.25
			if offset_x > 0.76 then
				offset_x = 0.0
				offset_y = offset_y + 0.25
			end
		end
	end
	shadowmapDebug(offset_x, offset_y)
	for i, _ in ipairs(render_debug_deferred) do
		if render_debug_deferred[i].enabled and render_debug_deferred[i].fullscreen then
			newView(this, "deferred_debug_fullsize", "default")
				setPass(this, "MAIN")
				bindFramebufferTexture(this, "g_buffer", render_debug_deferred[i].g_buffer_idx, texture_uniform)
				setUniform(this, multiplier_uniform, {render_debug_deferred[i].mask})
				drawQuad(this, 0, 0, 1, 1, screen_space_debug_material)
		end
	end
end

function transparency(camera_slot)
	newView(this, "TRANSPARENT", "hdr", TRANSPARENT_RENDER_MASK)
		setViewMode(this, VIEW_MODE_DEPTH_DESCENDING)
		setPass(this, "FORWARD")
		disableDepthWrite(this)
		enableBlending(this, "alpha")
		applyCamera(this, camera_slot)
		setActiveGlobalLightUniforms(this)
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
		
		renderTextMeshes(this)
end

function fur(camera_slot)
	if not render_fur then return end
	fur_view = newView(this, "FUR", "hdr", FUR_RENDER_MASK)
		setPass(this, "FUR")
		disableDepthWrite(this)
		enableBlending(this, "alpha")
		applyCamera(this, camera_slot)
		setActiveGlobalLightUniforms(this)
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
end

function water(camera_slot)
	water_view = newView(this, "WATER", "hdr", WATER_RENDER_MASK)
		setPass(this, "MAIN")
		disableDepthWrite(this)
		applyCamera(this, camera_slot)
		setActiveGlobalLightUniforms(this)
		bindFramebufferTexture(this, "g_buffer", 0, gbuffer0_uniform) -- refraction
		bindFramebufferTexture(this, "g_buffer", 1, gbuffer1_uniform) 
		bindFramebufferTexture(this, "g_buffer", 2, gbuffer2_uniform) 
		bindFramebufferTexture(this, "g_buffer", 3, gbuffer_depth_uniform) -- depth
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
end

function particles(camera_slot)
	if particles_enabled then
		newView(this, "particles", "hdr")
			setPass(this, "PARTICLES")
			disableDepthWrite(this)
			applyCamera(this, camera_slot)
			bindFramebufferTexture(this, "g_buffer", 3, depth_buffer_uniform)
			setActiveGlobalLightUniforms(this)
			renderParticles(this)
	end	
end

function shadowmap(ctx, camera_slot, layer_mask)
	newView(this, "shadow0", "shadowmap", layer_mask)
		setPass(this, "SHADOW")
		applyCamera(this, camera_slot)
		renderShadowmap(this, 0) 

	newView(this, "shadow1", "shadowmap", layer_mask)
		setPass(this, "SHADOW")         
		applyCamera(this, camera_slot)
		renderShadowmap(this, 1) 

	newView(this, "shadow2", "shadowmap", layer_mask)
		setPass(this, "SHADOW")         
		applyCamera(this, camera_slot)
		renderShadowmap(this, 2) 

	newView(this, "shadow3", "shadowmap", layer_mask)
		setPass(this, "SHADOW")         
		applyCamera(this, camera_slot)
		renderShadowmap(this, 3) 
		
		renderLocalLightsShadowmaps(this, camera_slot, { "point_light_shadowmap", "point_light2_shadowmap" })
		
	if blur_shadowmap then
		newView(this, "blur_shadowmap_h", "shadowmap_blur")
			setPass(this, "BLUR_H")
			disableDepthWrite(this)
			bindFramebufferTexture(this, "shadowmap", 0, shadowmap_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			drawQuad(this, 0, 0, 1, 1, blur_material)
			enableDepthWrite(this)

		newView(this, "blur_shadowmap_v", "shadowmap")
			setPass(this, "BLUR_V")
			disableDepthWrite(this)
			bindFramebufferTexture(this, "shadowmap_blur", 0, shadowmap_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			drawQuad(this, 0, 0, 1, 1, blur_material);
			enableDepthWrite(this)
	end
end

function ingameGUI()
	newView(this, "ingame_gui", "default")
		setPass(this, "MAIN")
		clear(this, CLEAR_DEPTH, 0x303030ff)
		renderIngameGUI(this)
end

-- called each frame
function render()
	local camera_slot = getCameraSlot()
	
	if render_shadowmap then
		shadowmap(ctx, camera_slot, DEFAULT_RENDER_MASK + FUR_RENDER_MASK + TERRAIN_RENDER_MASK)
	end
	rigid(camera_slot)
	
	doPostprocess(this, _ENV, "pre_transparent", camera_slot)

	particles(camera_slot)
	transparency(camera_slot)
	fur(camera_slot)
	water(camera_slot)
	
	if occlusion_culling_enabled then
		rasterizeOccluders(this, OCCLUDER_MASK)
	end
	renderModels(this, occlusion_culling_enabled)

	doPostprocess(this, _ENV, "main", camera_slot)

	tonemapping()

	doPostprocess(this, _ENV, "post_tonemapping", camera_slot)

	newView(this, "copy_to_linear", "default")
		clear(this, CLEAR_ALL, 0x00000000)
		disableDepthWrite(this)
		bindFramebufferTexture(this, "linear", 0, texture_uniform)
		drawQuad(this, 0, 0, 1, 1, screen_space_material)
	
	newView(this, "draw2d", "default")
		setPass(this, "MAIN")
		render2D(this)
	
	if SCENE_VIEW then
		renderEditorIcons(camera_slot)
		renderGizmo(camera_slot)
		renderDebug(ctx)
		renderSelectionOutline(ctx, camera_slot)
	end

	if GAME_VIEW or APP then
		ingameGUI()
	end

	if screenshot_request > 1 then
		-- we have to wait for a few frames to propagate changed resolution to ingame gui
		-- only then we can take a screeshot
		-- otherwise ingame gui would be constructed in gameview size
		-- 1st frame - set forceViewport
		-- 2nd frame - set ImGui's display size (ingame) to forced value
		-- 3rd frame - construct ingame gui with forced values
		-- 4th frame - render and save (save is internally two more frames)
		screenshot_request = screenshot_request - 1
		GameView.forceViewport(true, 4096, 2160)
	elseif screenshot_request == 1 then
		saveRenderbuffer(this, "default", 0, "screenshot.tga")
		GameView.forceViewport(false, 0, 0)
		screenshot_request = 0
	end
end

-- gui

local volume = 1
local paused = false
local timescale = 1

function onGUI()
	if GAME_VIEW then
		ImGui.SameLine()
		if ImGui.Button("Screenshot") then
			screenshot_request = 4
		end
		return
	end

	local changed
	ImGui.SameLine()
	changed, volume = ImGui.SliderFloat("Volume", volume, 0, 1)
	if changed then
		Audio.setMasterVolume(g_scene_audio, volume)
	end
	ImGui.SameLine()
	if ImGui.Button("Debug") then
		ImGui.OpenPopup("debug_popup")
	end

	ImGui.SameLine()
	changed, paused = ImGui.Checkbox("paused", paused)
	if changed then
		Engine.pause(g_engine, paused)
	end
	
	ImGui.SameLine()
	if ImGui.Button("Next frame") then Engine.nextFrame(g_engine) end
	
	ImGui.SameLine()
	changed, timescale = ImGui.SliderFloat("Timescale", timescale, 0, 1)
	if changed then
		Engine.setTimeMultiplier(g_engine, timescale)
	end
	
	
	if ImGui.BeginPopup("debug_popup") then
		for i, _ in ipairs(render_debug_deferred) do
			changed, render_debug_deferred[i].enabled = ImGui.Checkbox(render_debug_deferred[i].label, render_debug_deferred[i].enabled)
			if render_debug_deferred[i].enabled then
				ImGui.SameLine()
				changed, render_debug_deferred[i].fullscreen = ImGui.Checkbox("Fullsize###gbf" .. tostring(i), render_debug_deferred[i].fullscreen)
				
				if changed and render_debug_deferred[i].fullscreen then
					for j, _ in ipairs(render_debug_deferred) do
						render_debug_deferred[j].fullscreen = false
					end
					render_debug_deferred[i].fullscreen = true
				end
			end
		end
		
		changed, render_shadowmap_debug = ImGui.Checkbox("Shadowmap", render_shadowmap_debug)
		if render_shadowmap_debug then
			ImGui.SameLine()
			changed, render_shadowmap_debug_fullsize = ImGui.Checkbox("Fullsize###gbfsm", render_shadowmap_debug_fullsize)
		end
		if ImGui.Button("High details") then
			Renderer.setGlobalLODMultiplier(g_scene_renderer, 0.1)
		end
		if ImGui.Button("Toggle") then
			local v = not render_debug_deferred[1].enabled
			render_shadowmap_debug = v 
			render_debug_deferred[1].enabled = v
			render_debug_deferred[2].enabled = v
			render_debug_deferred[3].enabled = v
			render_debug_deferred[4].enabled = v
		end
		changed, disable_render = ImGui.Checkbox("Disabled rendering", disable_render)
		changed, render_shadowmap = ImGui.Checkbox("Render shadowmap", render_shadowmap)
		changed, blur_shadowmap = ImGui.Checkbox("Blur shadowmap", blur_shadowmap)
		changed, render_gizmos = ImGui.Checkbox("Render gizmos", render_gizmos)
		changed, render_fur = ImGui.Checkbox("Render fur", render_fur)
		
		ImGui.EndPopup()
	end
end