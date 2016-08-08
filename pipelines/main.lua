common = require "pipelines/common"
ctx = { pipeline = this, main_framebuffer = "forward" }
do_gamma_mapping = true

local deferred_enabled = false
local render_debug_deferred = { false, false, false, false }
local render_debug_deferred_fullsize = { false, false, false, false }

addFramebuffer(this, "default", {
	width = 1024,
	height = 1024,
	renderbuffers = {
		{ format = "rgba8" }
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
local blur_material = loadMaterial(this, "shaders/blur.mat")
local screen_space_material = loadMaterial(this, "shaders/screen_space.mat")
local gbuffer0_uniform = createUniform(this, "u_gbuffer0")
local gbuffer1_uniform = createUniform(this, "u_gbuffer1")
local gbuffer2_uniform = createUniform(this, "u_gbuffer2")
local gbuffer_depth_uniform = createUniform(this, "u_gbuffer_depth")
local deferred_material = loadMaterial(this, "shaders/deferred.mat")
local deferred_point_light_material = loadMaterial(this, "shaders/deferredpointlight.mat")
local gamma_mapping_material = loadMaterial(this, "shaders/gamma_mapping.mat")


function deferred(camera_slot)
	deferred_view = newView(this, "deferred")
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
		renderLightVolumes(this, deferred_point_light_material)
		disableBlending(this)
	
end

function main()
	main_view = newView(this, "MAIN")
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


function fur()
	fur_view = newView(this, "FUR")
		setPass(this, "FUR")
		setFramebuffer(this, ctx.main_framebuffer)
		disableDepthWrite(this)
		enableBlending(this, "alpha")
		applyCamera(this, "editor")
		setActiveGlobalLightUniforms(this)
		if deferred_enabled then
			renderModels(this, {deferred_view, fur_view})
		else
			renderModels(this, {main_view, fur_view})
		end
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
				setPass(ctx.pipeline, "SCREEN_SPACE")
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
				setPass(ctx.pipeline, "SCREEN_SPACE")
				setFramebuffer(ctx.pipeline, "default")
				bindFramebufferTexture(ctx.pipeline, "g_buffer", i - 1, ctx.texture_uniform)
				drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.screen_space_material)
		end
	end
end


function render()
	common.shadowmap(ctx, "editor")
	if deferred_enabled then
		deferred("editor")
		common.particles(ctx, "editor")
	else
		main(this)
		common.particles(ctx, "editor")
		pointLight(this)		
	end
	fur(this)
	common.renderEditorIcons(ctx)

	postprocessCallback(this, "editor")

	
	if do_gamma_mapping then
		newView(this, "SRGB")
			clear(this, CLEAR_ALL, 0x00000000)
			setPass(this, "GAMMA_MAPPING")
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "forward", 0, texture_uniform)
			drawQuad(this, 0, 0, 1, 1, gamma_mapping_material)
	end
	
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
		
		ImGui.EndPopup()
	end
end