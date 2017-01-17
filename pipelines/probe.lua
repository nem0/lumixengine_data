_G["game_pipeline_env"] = _ENV
common = require "pipelines/common"
ctx = { pipeline = this, main_framebuffer = "forward" }
do_gamma_mapping = true
fur_enabled = true

local DEFAULT_RENDER_MASK = 1
local TRANSPARENT_RENDER_MASK = 2
local WATER_RENDER_MASK = 4
local FUR_RENDER_MASK = 8
local ALL_RENDER_MASK = DEFAULT_RENDER_MASK + TRANSPARENT_RENDER_MASK + WATER_RENDER_MASK + FUR_RENDER_MASK

local render_debug_deferred = { false, false, false, false }
local render_debug_deferred_fullsize = { false, false, false, false }

addFramebuffer(this, "default", {
	width = 1024,
	height = 1024,
	renderbuffers = {
		{ format = "rgba8" },
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
local screen_space_material = Engine.loadResource(g_engine,"pipelines/screenspace/screenspace.mat", "material")
local gbuffer0_uniform = createUniform(this, "u_gbuffer0")
local gbuffer1_uniform = createUniform(this, "u_gbuffer1")
local gbuffer2_uniform = createUniform(this, "u_gbuffer2")
local gbuffer_depth_uniform = createUniform(this, "u_gbuffer_depth")
local deferred_material = Engine.loadResource(g_engine,"pipelines/pbr/pbr.mat", "material")
local pbr_local_light_material = Engine.loadResource(g_engine, "pipelines/pbr/pbrlocallight.mat", "material")
local gamma_mapping_material = Engine.loadResource(g_engine,"pipelines/common/gamma_mapping.mat", "material")
local irradiance_map_uniform = createUniform(this, "u_irradiance_map")
local radiance_map_uniform = createUniform(this, "u_radiance_map")
local default_cube_texture = Engine.loadResource(g_engine, "pipelines/pbr/default_probe.dds", "texture")


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
		bindTexture(this, irradiance_map_uniform, default_cube_texture)
		bindTexture(this, irradiance_map_uniform, default_cube_texture)
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
		bindTexture(this, irradiance_map_uniform, default_cube_texture)
		bindTexture(this, irradiance_map_uniform, default_cube_texture)
		renderLightVolumes(this, pbr_local_light_material)
		disableBlending(this)
end

function main()
	main_view = newView(this, "MAIN", DEFAULT_RENDER_MASK)
		setPass(this, "MAIN")
		enableDepthWrite(this)
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
		enableRGBWrite(this)
		setFramebuffer(this, ctx.main_framebuffer)
		applyCamera(this, "probe")
		setActiveGlobalLightUniforms(this)
		renderDebugShapes(this)
end

function pointLight()
	newView(this, "POINT_LIGHT")
		setPass(this, "POINT_LIGHT")
		setFramebuffer(this, ctx.main_framebuffer)
		disableDepthWrite(this)
		enableBlending(this, "add")
		applyCamera(this, "probe")
		renderPointLightLitGeometry(this)
end

function ingameGUI()
	newView(this, "ingame_gui")
		setPass(this, "MAIN")
		setFramebuffer(this, "default")
		clear(this, CLEAR_DEPTH, 0x303030ff)
		renderIngameGUI(this)
end

function render()
	common.shadowmap(ctx, "probe", DEFAULT_RENDER_MASK)
	deferred("probe")

	doPostprocess(this, _ENV, "pre_transparent", "probe")

	renderModels(this, ALL_RENDER_MASK)
	
	doPostprocess(this, _ENV, "main", "probe")

	if do_gamma_mapping then
		newView(this, "SRGB")
			setPass(this, "MAIN")
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "forward", 0, texture_uniform)
			drawQuad(this, 0, 0, 1, 1, gamma_mapping_material)
	end
	
	ingameGUI(ctx)
end
