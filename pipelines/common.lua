local module = {}
local lua_script_type = Engine.getComponentType("lua_script")

module.particles_enabled = true
module.render_gizmos = true
module.blur_shadowmap = true
module.render_shadowmap_debug = false
module.render_shadowmap_debug_fullsize = false

function doPostprocess(pipeline, this_env, slot, camera_slot)
	local scene_renderer = Renderer.getPipelineScene(pipeline)
	local universe = Engine.getSceneUniverse(scene_renderer)
	local scene_lua_script = Engine.getScene(universe, "lua_script")
	local camera_cmp = Renderer.getCameraInSlot(scene_renderer, camera_slot)
	if camera_cmp < 0 then return end
	local camera_entity = Renderer.getCameraEntity(scene_renderer, camera_cmp)
	local script_cmp = Engine.getComponent(universe, camera_entity, lua_script_type)
	if script_cmp < 0 then return end
	local script_count = LuaScript.getScriptCount(scene_lua_script, script_cmp)
	for i = 1, script_count do
		local env = LuaScript.getEnvironment(scene_lua_script, script_cmp, i - 1)
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

function module.renderEditorIcons(ctx)
	if module.render_gizmos then
		newView(ctx.pipeline, "editor", 0xFFFFffffFFFFffff)
			bindFramebufferTexture(ctx.pipeline, ctx.main_framebuffer, 1, ctx.depth_buffer_uniform)
			setPass(ctx.pipeline, "EDITOR")
			setFramebuffer(ctx.pipeline, "default")
			enableDepthWrite(ctx.pipeline)
			enableBlending(ctx.pipeline, "alpha")
			applyCamera(ctx.pipeline, "editor")
			renderIcons(ctx.pipeline)
	end
end

function module.renderGizmo(ctx)
	if module.render_gizmos then
		newView(ctx.pipeline, "gizmo")
			setPass(ctx.pipeline, "EDITOR")
			setFramebuffer(ctx.pipeline, "default")
			applyCamera(ctx.pipeline, "editor")
			renderGizmos(ctx.pipeline)
	end
end

function module.shadowmapDebug(ctx, x, y)
	if module.render_shadowmap_debug then
		newView(ctx.pipeline, "shadowmap_debug")
			setPass(ctx.pipeline, "MAIN")
			setFramebuffer(ctx.pipeline, "default")
			bindFramebufferTexture(ctx.pipeline, "shadowmap", 0, ctx.texture_uniform)
			drawQuad(ctx.pipeline, 0.01 + x, 0.01 + y, 0.23, 0.23, ctx.screen_space_material)
	end
	if module.render_shadowmap_debug_fullsize then
		newView(ctx.pipeline, "shadowmap_debug_fullsize")
			setPass(ctx.pipeline, "MAIN")
			setFramebuffer(ctx.pipeline, "default")
			bindFramebufferTexture(ctx.pipeline, "shadowmap", 0, ctx.texture_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.screen_space_material)
	end
end

function module.initShadowmap(ctx, shadowmap_size)
	addFramebuffer(ctx.pipeline, "shadowmap_blur", {
		width = shadowmap_size,
		height = shadowmap_size,
		renderbuffers = {
			{ format = "r32f", min_filter = "anisotropic", mag_filter = "anisotropic" }
		}
	})

	addFramebuffer(ctx.pipeline, "shadowmap", {
		width = shadowmap_size,
		height = shadowmap_size,
		renderbuffers = {
			{format="r32f", min_filter = "anisotropic", mag_filter = "anisotropic" },
			{format = "depth24"}
		}
	})

	addFramebuffer(ctx.pipeline, "point_light_shadowmap", {
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth24"}
		}
	})

	addFramebuffer(ctx.pipeline, "point_light2_shadowmap", {
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth24"}
		}
	})
	ctx.shadowmap_uniform = createUniform(ctx.pipeline, "u_texShadowmap")
	module.blur_shadowmap = true
	module.render_shadowmap_debug = false
end


function module.init(ctx)
	ctx.screen_space_material = Engine.loadResource(g_engine, "pipelines/screenspace/screenspace.mat", "material")
	ctx.screen_space_debug_material = Engine.loadResource(g_engine, "pipelines/screenspace/screenspace_debug.mat", "material")
	ctx.texture_uniform = createUniform(ctx.pipeline, "u_texture")
	ctx.blur_material = Engine.loadResource(g_engine, "pipelines/common/blur.mat", "material")
	ctx.downsample_material = Engine.loadResource(g_engine, "pipelines/common/downsample.mat", "material")
	ctx.depth_buffer_uniform = createUniform(ctx.pipeline, "u_depthBuffer")
	ctx.multiplier_uniform = createVec4ArrayUniform(ctx.pipeline, "u_multiplier", 1)
end


function module.shadowmap(ctx, camera_slot, layer_mask)
	newView(ctx.pipeline, "shadow0", layer_mask)
		setPass(ctx.pipeline, "SHADOW")
		applyCamera(ctx.pipeline, camera_slot)
		setFramebuffer(ctx.pipeline, "shadowmap")
		renderShadowmap(ctx.pipeline, 0) 

	newView(ctx.pipeline, "shadow1", layer_mask)
		setPass(ctx.pipeline, "SHADOW")         
		applyCamera(ctx.pipeline, camera_slot)
		setFramebuffer(ctx.pipeline, "shadowmap")
		renderShadowmap(ctx.pipeline, 1) 

	newView(ctx.pipeline, "shadow2", layer_mask)
		setPass(ctx.pipeline, "SHADOW")         
		applyCamera(ctx.pipeline, camera_slot)
		setFramebuffer(ctx.pipeline, "shadowmap")
		renderShadowmap(ctx.pipeline, 2) 

	newView(ctx.pipeline, "shadow3", layer_mask)
		setPass(ctx.pipeline, "SHADOW")         
		applyCamera(ctx.pipeline, camera_slot)
		setFramebuffer(ctx.pipeline, "shadowmap")
		renderShadowmap(ctx.pipeline, 3) 
		
		renderLocalLightsShadowmaps(ctx.pipeline, camera_slot, { "point_light_shadowmap", "point_light2_shadowmap" })
		
	if module.blur_shadowmap then
		newView(ctx.pipeline, "blur_shadowmap_h")
			setPass(ctx.pipeline, "BLUR_H")
			setFramebuffer(ctx.pipeline, "shadowmap_blur")
			disableDepthWrite(ctx.pipeline)
			bindFramebufferTexture(ctx.pipeline, "shadowmap", 0, ctx.shadowmap_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.blur_material)
			enableDepthWrite(ctx.pipeline)

		newView(ctx.pipeline, "blur_shadowmap_v")
			setPass(ctx.pipeline, "BLUR_V")
			setFramebuffer(ctx.pipeline, "shadowmap")
			disableDepthWrite(ctx.pipeline)
			bindFramebufferTexture(ctx.pipeline, "shadowmap_blur", 0, ctx.shadowmap_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.blur_material);
			enableDepthWrite(ctx.pipeline)
	end
end

function module.particles(ctx, camera_slot)
	if module.particles_enabled then
		newView(ctx.pipeline, "particles")
			setPass(ctx.pipeline, "PARTICLES")
			disableDepthWrite(ctx.pipeline)
			applyCamera(ctx.pipeline, camera_slot)
			bindFramebufferTexture(ctx.pipeline, "g_buffer", 3, ctx.depth_buffer_uniform)
			setActiveGlobalLightUniforms(ctx.pipeline)
			renderParticles(ctx.pipeline)
	end	
end


return module
