common = require "pipelines/common"
ctx = { pipeline = this, main_framebuffer = "linear" }
if APP then
	camera = "main"
elseif GAME_VIEW  then
	camera = "main"
else
	camera = "editor"
end

local DEFAULT_RENDER_MASK = 1
local TRANSPARENT_RENDER_MASK = 2
local WATER_RENDER_MASK = 4
local FUR_RENDER_MASK = 8
local ALL_RENDER_MASK = DEFAULT_RENDER_MASK + TRANSPARENT_RENDER_MASK + WATER_RENDER_MASK + FUR_RENDER_MASK
local screenshot_request = 0
local render_fur = true
local render_shadowmap = true
local disable_render = false
local render_debug_deferred = 
{ 
 { label = "Albedo", enabled = false, fullscreen = false, mask = {1, 1, 1, 0}, g_buffer_idx = 0},
 { label = "Normal", enabled = false, fullscreen = false, mask = {1, 1, 1, 0}, g_buffer_idx = 1},
 { label = "Roughness", enabled = false, fullscreen = false, mask = {0, 0, 0, 1}, g_buffer_idx = 0},
 { label = "Metallic", enabled = false, fullscreen = false, mask = {0, 0, 0, 1}, g_buffer_idx = 1},
 { label = "AO", enabled = false, fullscreen = false, mask = {1, 1, 1, 0}, g_buffer_idx = 2},
 { label = "Depth", enabled = false, fullscreen = false, mask = {1, 0, 0, 0}, g_buffer_idx = 3},
}

addFramebuffer(this, "linear", {
	width = 1024,
	height = 1024,
	size_ratio = {1, 1},
	renderbuffers = {
		{ format = "rgba8" },
		{ format = "depth24stencil8" }
	}
})

if not APP then
	addFramebuffer(this, "default", {
		width = 1024,
		height = 1024,
		renderbuffers = {
			{ format = "rgba8" },
			{ format = "depth24stencil8" }
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
  
common.init(ctx)
common.initShadowmap(ctx, 1024)


local texture_uniform = createUniform(this, "u_texture")
local screen_space_material = Engine.loadResource(g_engine, "pipelines/screenspace/screenspace.mat", "material")
local gbuffer0_uniform = createUniform(this, "u_gbuffer0")
local gbuffer1_uniform = createUniform(this, "u_gbuffer1")
local gbuffer2_uniform = createUniform(this, "u_gbuffer2")
local gbuffer_depth_uniform = createUniform(this, "u_gbuffer_depth")
local irradiance_map_uniform = createUniform(this, "u_irradiance_map")
local radiance_map_uniform = createUniform(this, "u_radiance_map")
local pbr_material = Engine.loadResource(g_engine, "pipelines/pbr/pbr.mat", "material")
local pbr_local_light_material = Engine.loadResource(g_engine, "pipelines/pbr/pbrlocallight.mat", "material")
local gamma_mapping_material = Engine.loadResource(g_engine, "pipelines/common/gamma_mapping.mat", "material")


function deferred(camera_slot)
	deferred_view = newView(this, "geometry_pass", "g_buffer", DEFAULT_RENDER_MASK)
		setPass(this, "DEFERRED")
		applyCamera(this, camera_slot)
		clear(this, CLEAR_ALL, 0x00000000)
		
		setStencil(this, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(this, 0xff)
		setStencilRef(this, 1)
	
	newView(this, "clear_main", ctx.main_framebuffer)
		-- there are strange artifacts on some platforms without this clear
		clear(this, CLEAR_ALL, 0x00000000)
	
	newView(this, "copyRenderbuffer", ctx.main_framebuffer);
		copyRenderbuffer(this, "g_buffer", 3, ctx.main_framebuffer, 1)

	newView(this, "decals", "g_buffer")
		setPass(this, "DEFERRED")
		disableDepthWrite(this)
		applyCamera(this, camera_slot)
		bindFramebufferTexture(this, ctx.main_framebuffer, 1, gbuffer_depth_uniform)
		renderDecalsVolumes(this)
		
	newView(this, "light_pass", ctx.main_framebuffer)
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
		
	newView(this, "local_light_pass", ctx.main_framebuffer)
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

	newView(this, "deferred_debug_shapes", ctx.main_framebuffer)
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


function water()
	water_view = newView(this, "WATER", ctx.main_framebuffer, WATER_RENDER_MASK)
		setPass(this, "MAIN")
		disableDepthWrite(this)
		applyCamera(this, camera)
		setActiveGlobalLightUniforms(this)
		bindFramebufferTexture(this, "g_buffer", 0, gbuffer0_uniform) -- refraction
		bindFramebufferTexture(this, "g_buffer", 1, gbuffer1_uniform) 
		bindFramebufferTexture(this, "g_buffer", 2, gbuffer2_uniform) 
		bindFramebufferTexture(this, "g_buffer", 3, gbuffer_depth_uniform) -- depth
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
end

function transparency()
	newView(this, "TRANSPARENT", ctx.main_framebuffer, TRANSPARENT_RENDER_MASK)
		setViewMode(this, VIEW_MODE_DEPTH_DESCENDING)
		setPass(this, "FORWARD")
		disableDepthWrite(this)
		enableBlending(this, "alpha")
		applyCamera(this, camera)
		setActiveGlobalLightUniforms(this)
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
end

function fur()
	if not render_fur then return end
	fur_view = newView(this, "FUR", ctx.main_framebuffer, FUR_RENDER_MASK)
		setPass(this, "FUR")
		disableDepthWrite(this)
		enableBlending(this, "alpha")
		applyCamera(this, camera)
		setActiveGlobalLightUniforms(this)
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
end


function renderDebug(ctx)
	local offset_x = 0
	local offset_y = 0
	for i, _ in ipairs(render_debug_deferred) do
		if render_debug_deferred[i].enabled then
			newView(ctx.pipeline, "deferred_debug_"..tostring(i), "default")
				setPass(ctx.pipeline, "MAIN")
				bindFramebufferTexture(ctx.pipeline, "g_buffer", render_debug_deferred[i].g_buffer_idx, ctx.texture_uniform)
				setUniform(ctx.pipeline, ctx.multiplier_uniform, {render_debug_deferred[i].mask})
				drawQuad(ctx.pipeline, 0.01 + offset_x, 0.01 + offset_y, 0.23, 0.23, ctx.screen_space_debug_material)
				
			offset_x = offset_x + 0.25
			if offset_x > 0.76 then
				offset_x = 0.0
				offset_y = offset_y + 0.25
			end
		end
	end
	common.shadowmapDebug(ctx, offset_x, offset_y)
	for i, _ in ipairs(render_debug_deferred) do
		if render_debug_deferred[i].enabled and render_debug_deferred[i].fullscreen then
			newView(ctx.pipeline, "deferred_debug_fullsize", "default")
				setPass(ctx.pipeline, "MAIN")
				bindFramebufferTexture(ctx.pipeline, "g_buffer", render_debug_deferred[i].g_buffer_idx, ctx.texture_uniform)
				setUniform(ctx.pipeline, ctx.multiplier_uniform, {render_debug_deferred[i].mask})
				drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.screen_space_debug_material)
		end
	end
end

function ingameGUI()
	newView(this, "ingame_gui", "default")
		setPass(this, "MAIN")
		clear(this, CLEAR_DEPTH, 0x303030ff)
		renderIngameGUI(this)
end

function render()
	if disable_render then
		newView(ctx.pipeline, "render_disable", "default")
			clear(this, CLEAR_ALL, 0x00000000)
			setPass(this, "MAIN")
		return
	end

	if render_shadowmap then
		common.shadowmap(ctx, camera, DEFAULT_RENDER_MASK + FUR_RENDER_MASK)
	end
	deferred(camera)
	common.particles(ctx, camera)

	doPostprocess(this, _ENV, "pre_transparent", camera)

	water()
	fur()
	transparency()
	
	renderModels(this, ALL_RENDER_MASK)
	
	doPostprocess(this, _ENV, "main", camera)
	
	
	newView(this, "draw2d", ctx.main_framebuffer)
		render2D(this)
	
	newView(this, "SRGB", "default")
		clear(this, CLEAR_ALL, 0x00000000)
		setPass(this, "MAIN")
		bindFramebufferTexture(this, "linear", 0, texture_uniform)
		drawQuad(this, 0, 0, 1, 1, gamma_mapping_material)

	if SCENE_VIEW then
		common.renderEditorIcons(ctx)
		common.renderGizmo(ctx)
		renderDebug(ctx)
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
		
		changed, common.render_shadowmap_debug = ImGui.Checkbox("Shadowmap", common.render_shadowmap_debug)
		if common.render_shadowmap_debug then
			ImGui.SameLine()
			changed, common.render_shadowmap_debug_fullsize = ImGui.Checkbox("Fullsize###gbfsm", common.render_shadowmap_debug_fullsize)
		end
		if ImGui.Button("High details") then
			Renderer.setGlobalLODMultiplier(g_scene_renderer, 0.1)
		end
		if ImGui.Button("Toggle") then
			local v = not render_debug_deferred[1].enabled
			common.render_shadowmap_debug = v 
			render_debug_deferred[1].enabled = v
			render_debug_deferred[2].enabled = v
			render_debug_deferred[3].enabled = v
			render_debug_deferred[4].enabled = v
		end
		changed, disable_render = ImGui.Checkbox("Disabled rendering", disable_render)
		changed, render_shadowmap = ImGui.Checkbox("Render shadowmap", render_shadowmap)
		changed, common.blur_shadowmap = ImGui.Checkbox("Blur shadowmap", common.blur_shadowmap)
		changed, common.render_gizmos = ImGui.Checkbox("Render gizmos", common.render_gizmos)
		changed, render_fur = ImGui.Checkbox("Render fur", render_fur)
		
		ImGui.EndPopup()
	end
end