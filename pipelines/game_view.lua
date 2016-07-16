common = require "pipelines/common"
ctx = { pipeline = this, main_framebuffer = "forward" }
do_gamma_mapping = true

local sky_enabled = true
local cube_sky_enabled = true
local deferred_enabled = false
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
		{ format = "depth24" }
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
		{ format = "depth24" }
	}
})
  
common.init(ctx)
common.initShadowmap(ctx)


local texture_uniform = createUniform(this, "u_texture")
local blur_material = loadMaterial(this, "shaders/blur.mat")
local screen_space_material = loadMaterial(this, "shaders/screen_space.mat")
local sky_material = loadMaterial(this, "shaders/sky.mat")
local cube_sky_material = loadMaterial(this, "models/sky/miramar/sky.mat")
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
		
	if sky_enabled then
		newView(this, "sky")
			setPass(this, "SKY")
			setStencil(this, STENCIL_OP_PASS_Z_KEEP 
				| STENCIL_OP_FAIL_Z_KEEP 
				| STENCIL_OP_FAIL_S_KEEP 
				| STENCIL_TEST_NOTEQUAL)
			setStencilRMask(this, 1)
			setStencilRef(this, 1)

			setFramebuffer(this, ctx.main_framebuffer)
			setActiveGlobalLightUniforms(this)
			disableDepthWrite(this)
			if cube_sky_enabled then
				drawQuad(this, 0, 0, 1, 1, cube_sky_material)
			else
				drawQuad(this, 0, 0, 1, 1, sky_material)
			end
	end
end

function main()
	if sky_enabled then
		newView(this, "sky")
			setPass(this, "SKY")
			setFramebuffer(this, ctx.main_framebuffer)
			disableDepthWrite(this)
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
			setActiveGlobalLightUniforms(this, sky_material)
			if cube_sky_enabled then
				drawQuad(this, 0, 0, 1, 1, cube_sky_material)
			else
				drawQuad(this, 0, 0, 1, 1, sky_material)
			end
	end

	main_view = newView(this, "MAIN")
		setPass(this, "MAIN")
		enableDepthWrite(this)
		if not sky_enabled then
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
		end
		enableRGBWrite(this)
		setFramebuffer(this, ctx.main_framebuffer)
		applyCamera(this, "main")
		setActiveGlobalLightUniforms(this)
		renderDebugShapes(this)
end


function fur()
	fur_view = newView(this, "FUR")
		setPass(this, "FUR")
		setFramebuffer(this, ctx.main_framebuffer)
		disableDepthWrite(this)
		enableBlending(this, "alpha")
		applyCamera(this, "main")
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
		applyCamera(this, "main")
		renderPointLightLitGeometry(this)
end

function ingameGUI()
	newView(this, "ingame_gui")
		setPass(this, "IMGUI")
		setFramebuffer(this, "default")
		clear(this, CLEAR_DEPTH, 0x303030ff)
		renderIngameGUI(this)
end

function render()
	common.shadowmap(ctx, "main")
	if deferred_enabled then
		deferred("main")
		common.particles(ctx, "main")
	else
		main(this)
		common.particles(ctx, "main")
		pointLight(this)		
	end
	fur(this)

	postprocessCallback(this, "main")

	if do_gamma_mapping then
		newView(this, "SRGB")
			setPass(this, "GAMMA_MAPPING")
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "forward", 0, texture_uniform)
			drawQuad(this, 0, 0, 1, 1, gamma_mapping_material)
	end
	
	ingameGUI(ctx)
end
