common = require "pipelines/common"
ctx = { pipeline = this, main_framebuffer = "forward" }
do_gamma_mapping = true

local DEFAULT_RENDER_MASK = 1
local TRANSPARENT_RENDER_MASK = 2
local WATER_RENDER_MASK = 4
local FUR_RENDER_MASK = 8
local ALL_RENDER_MASK = DEFAULT_RENDER_MASK + TRANSPARENT_RENDER_MASK + WATER_RENDER_MASK + FUR_RENDER_MASK
local render_fur = true
local deferred_enabled = true
local render_debug_deferred = { false, false, false, false }
local render_debug_deferred_fullsize = { false, false, false, false }

addFramebuffer(this, "default", {
	width = 1024,
	height = 1024,
	renderbuffers = {
		{ format = "rgba8" },
		{ format = "depth24stencil8" }
	}
})

addFramebuffer(this, "forward", {
	width = 1024,
	height = 1024,
	size_ratio = {1, 1},
	renderbuffers = {
		{ format = "rgba8" },
		{ format = "depth24stencil8" }
	}
})

addFramebuffer(this, "g_buffer", {
	width = 1024,
	height = 1024,
	screen_size = true,
	renderbuffers = {
		{ format = "rgba8" },
		{ format = "rgba8" },
		{ format = "rgba8" },
		{ format = "depth24stencil8" }
	}
})
  
common.init(ctx)
common.initShadowmap(ctx)


local texture_uniform = createUniform(this, "u_texture")
local screen_space_material = Engine.loadResource(g_engine, "pipelines/screenspace/screenspace.mat", "material")
local gbuffer0_uniform = createUniform(this, "u_gbuffer0")
local gbuffer1_uniform = createUniform(this, "u_gbuffer1")
local gbuffer2_uniform = createUniform(this, "u_gbuffer2")
local gbuffer_depth_uniform = createUniform(this, "u_gbuffer_depth")
local irradiance_map_uniform = createUniform(this, "u_irradiance_map")
local radiance_map_uniform = createUniform(this, "u_radiance_map")
local lut_uniform = createUniform(this, "u_LUT")
local lut_texture = Engine.loadResource(g_engine, "pipelines/pbr/lut.tga", "texture")
local deferred_material = Engine.loadResource(g_engine, "pipelines/common/deferred.mat", "material")
local deferred_point_light_material = Engine.loadResource(g_engine, "pipelines/common/deferredpointlight.mat", "material")
local gamma_mapping_material = Engine.loadResource(g_engine, "pipelines/common/gamma_mapping.mat", "material")


function deferred(camera_slot)
	deferred_view = newView(this, "deferred", DEFAULT_RENDER_MASK)
		setPass(this, "DEFERRED")
		setFramebuffer(this, "g_buffer")
		applyCamera(this, camera_slot)
		clear(this, CLEAR_ALL, 0x00000000)
		
		setStencil(this, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(this, 0xff)
		setStencilRef(this, 1)
	
	newView(this, "copyRenderbuffer");
		copyRenderbuffer(this, "g_buffer", 3, ctx.main_framebuffer, 1)
		
	newView(this, "decals")
		setPass(this, "DEFERRED")
		disableDepthWrite(this)
		setFramebuffer(this, "g_buffer")
		applyCamera(this, camera_slot)
		bindFramebufferTexture(this, ctx.main_framebuffer, 1, gbuffer_depth_uniform)
		renderDecalsVolumes(this)
	
	newView(this, "main")
		setPass(this, "MAIN")
		setFramebuffer(this, ctx.main_framebuffer)
		applyCamera(this, camera_slot)
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
		
		setActiveGlobalLightUniforms(this)
		bindFramebufferTexture(this, "g_buffer", 0, gbuffer0_uniform)
		bindFramebufferTexture(this, "g_buffer", 1, gbuffer1_uniform)
		bindFramebufferTexture(this, "g_buffer", 2, gbuffer2_uniform)
		bindFramebufferTexture(this, "g_buffer", 3, gbuffer_depth_uniform)
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
		bindTexture(this, lut_uniform, lut_texture)
		drawQuad(this, 0, 0, 1, 1, deferred_material)
		
	newView(this, "deferred_debug_shapes")
		setPass(this, "EDITOR")
		setFramebuffer(this, ctx.main_framebuffer)
		applyCamera(this, camera_slot)
		setStencil(this, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(this, 0xff)
		setStencilRef(this, 1)
		renderDebugShapes(this)
		
	newView(this, "deferred_local_light")
		setPass(this, "MAIN")
		setFramebuffer(this, ctx.main_framebuffer)
		disableDepthWrite(this)
		enableBlending(this, "add")
		applyCamera(this, camera_slot)
		bindFramebufferTexture(this, "g_buffer", 0, gbuffer0_uniform)
		bindFramebufferTexture(this, "g_buffer", 1, gbuffer1_uniform)
		bindFramebufferTexture(this, "g_buffer", 2, gbuffer2_uniform)
		bindFramebufferTexture(this, "g_buffer", 3, gbuffer_depth_uniform)
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
		bindTexture(this, lut_uniform, lut_texture)
		disableBlending(this)
	
end

function main()
	main_view = newView(this, "MAIN", DEFAULT_RENDER_MASK)
		setStencil(this, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(this, 0xff)
		setStencilRef(this, 1)
		setPass(this, "MAIN")
		enableDepthWrite(this)
		clear(this, CLEAR_ALL, 0xffffFFFF)
		enableRGBWrite(this)
		setFramebuffer(this, ctx.main_framebuffer)
		applyCamera(this, "editor")
		setActiveGlobalLightUniforms(this)
		renderDebugShapes(this)
end

function water()
	water_view = newView(this, "WATER", WATER_RENDER_MASK)
		setPass(this, "MAIN")
		setFramebuffer(this, ctx.main_framebuffer)
		disableDepthWrite(this)
		applyCamera(this, "editor")
		setActiveGlobalLightUniforms(this)
		bindFramebufferTexture(this, "g_buffer", 0, gbuffer0_uniform) -- refraction
		bindFramebufferTexture(this, "g_buffer", 1, gbuffer1_uniform) 
		bindFramebufferTexture(this, "g_buffer", 2, gbuffer2_uniform) 
		bindFramebufferTexture(this, "g_buffer", 3, gbuffer_depth_uniform) -- depth
		bindEnvironmentMaps(this, irradiance_map_uniform, radiance_map_uniform)
		bindTexture(this, lut_uniform, lut_texture)
end

function fur()
	if not render_fur then return end
	fur_view = newView(this, "FUR", FUR_RENDER_MASK)
		setPass(this, "FUR")
		setFramebuffer(this, ctx.main_framebuffer)
		disableDepthWrite(this)
		enableBlending(this, "alpha")
		applyCamera(this, "editor")
		setActiveGlobalLightUniforms(this)
end


function pointLight()
	newView(this, "POINT_LIGHT")
		setPass(this, "POINT_LIGHT")
		setFramebuffer(this, ctx.main_framebuffer)
		disableDepthWrite(this)
		enableBlending(this, "add")
		applyCamera(this, "editor")
		renderPointLightLitGeometry(this)
end



function renderDebug(ctx)
	local offset_x = 0
	local offset_y = 0
	for i = 1, 4 do
		if render_debug_deferred[i] then
			newView(ctx.pipeline, "deferred_debug_"..tostring(i))
				setPass(ctx.pipeline, "MAIN")
				setFramebuffer(ctx.pipeline, "default")
				bindFramebufferTexture(ctx.pipeline, "g_buffer", i - 1, ctx.texture_uniform)
				drawQuad(ctx.pipeline, 0.01 + offset_x, 0.01 + offset_y, 0.23, 0.23, ctx.screen_space_material)
				
			offset_x = offset_x + 0.25
			if offset_x > 0.76 then
				offset_x = 0.0
				offset_y = offset_y + 0.25
			end
		end
	end
	common.shadowmapDebug(ctx, offset_x, offset_y)
	for i = 1, 4 do
		if render_debug_deferred_fullsize[i] and render_debug_deferred[i] then
			newView(ctx.pipeline, "deferred_debug_fullsize")
				setPass(ctx.pipeline, "MAIN")
				setFramebuffer(ctx.pipeline, "default")
				bindFramebufferTexture(ctx.pipeline, "g_buffer", i - 1, ctx.texture_uniform)
				drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.screen_space_material)
		end
	end
end


function render()
	common.shadowmap(ctx, "editor", DEFAULT_RENDER_MASK)
	if deferred_enabled then
		deferred("editor")
		common.particles(ctx, "editor")
	else
		main(this)
		common.particles(ctx, "editor")
		pointLight(this)		
	end


	doPostprocess(this, _ENV, "pre_transparent", "editor")

	water()
	fur()

	renderModels(this, ALL_RENDER_MASK)
	
	doPostprocess(this, _ENV, "main", "editor")
	
	if do_gamma_mapping then
		newView(this, "SRGB")
			clear(this, CLEAR_ALL, 0x00000000)
			setPass(this, "MAIN")
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "forward", 0, texture_uniform)
			drawQuad(this, 0, 0, 1, 1, gamma_mapping_material)
	end
	
	common.renderEditorIcons(ctx)
	common.renderGizmo(ctx)
	renderDebug(ctx)
end

function onGUI()
	local changed
	ImGui.SameLine()
	if ImGui.Button("Debug") then
		ImGui.OpenPopup("debug_popup")
	end
	if ImGui.BeginPopup("debug_popup") then
		for i = 1, 4 do
			changed, render_debug_deferred[i] = ImGui.Checkbox("GBuffer " .. tostring(i), render_debug_deferred[i])
			if render_debug_deferred[i] then
				ImGui.SameLine()
				changed, render_debug_deferred_fullsize[i] = ImGui.Checkbox("Fullsize###gbf" .. tostring(i), render_debug_deferred_fullsize[i])
				
				if changed and render_debug_deferred_fullsize[i] then
					for j = 1, 4 do
						render_debug_deferred_fullsize[j] = false
					end
					render_debug_deferred_fullsize[i] = true
				end
			end
		end
		
		changed, common.render_shadowmap_debug = ImGui.Checkbox("Shadowmap", common.render_shadowmap_debug)
		if common.render_shadowmap_debug then
			ImGui.SameLine()
			changed, common.render_shadowmap_debug_fullsize = ImGui.Checkbox("Fullsize###gbfsm", common.render_shadowmap_debug_fullsize)
		end
		if ImGui.Button("Toggle") then
			local v = not render_debug_deferred[1]
			common.render_shadowmap_debug = v 
			render_debug_deferred[1] = v
			render_debug_deferred[2] = v
			render_debug_deferred[3] = v
			render_debug_deferred[4] = v
		end
		changed, common.blur_shadowmap = ImGui.Checkbox("Blur shadowmap", common.blur_shadowmap)
		changed, deferred_enabled = ImGui.Checkbox("Deferred", deferred_enabled)
		changed, common.render_gizmos = ImGui.Checkbox("Render gizmos", common.render_gizmos)
		changed, render_fur = ImGui.Checkbox("Render fur", render_fur)
		
		ImGui.EndPopup()
	end
end