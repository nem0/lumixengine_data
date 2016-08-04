enabled = true
local camera_cmp_type = Engine.getComponentType("camera")

function initPostprocess(pipeline, env)
	env.ctx.godrays_material = loadMaterial(pipeline, "shaders/godrays.mat")
	env.ctx.global_light_screen_pos_uniform = createUniform(pipeline, "u_light_screen_pos")
end

function vecAdd(a, b)
	return { a[1] + b[1], a[2] + b[2], a[3] + b[3]}
end

function computeLightScreenPos()
	local camera_entity = this
	local camera_cmp = Engine.getComponent(g_universe, camera_entity, camera_cmp_type)
	if camera_cmp == -1 then return end
	
	local light_cmp = Renderer.getActiveGlobalLight(g_scene_renderer)
	local light_entity = Renderer.getGlobalLightEntity(g_scene_renderer, light_cmp)
	
	local camera_pos = Engine.getEntityPosition(g_universe, camera_entity)
	local light_rot = Engine.getEntityRotation(g_universe, light_entity)
	local light_dir = Engine.multVecQuat({0, 0, 1}, light_rot)
	
	light_dir[1] = -light_dir[1]
	light_dir[2] = -light_dir[2]
	light_dir[3] = -light_dir[3]
	
	local light_pos = vecAdd(camera_pos, light_dir)
	local matrix = Renderer.getCameraViewProjection(g_scene_renderer, camera_cmp)
	local projected = Engine.multMatrixVec(matrix, {light_pos[1], light_pos[2], light_pos[3], 1})
	return { projected[1] / projected[4] * 0.5 + 0.5, 1 - (projected[2] / projected[4] * 0.5 + 0.5), projected[3], projected[4] }
end

function onGUI()
	ImGui.Text("x = " .. xxx[1] .. " " .. xxx[2])
end


function postprocess(pipeline, env)
	if not enabled then return end
	
	newView(pipeline, "godrays")
		local light_screen_pos = computeLightScreenPos()
		setUniform(pipeline, env.ctx.global_light_screen_pos_uniform, {light_screen_pos})
		setPass(pipeline, "MAIN")
		enableBlending(pipeline, "add")
		--disableBlending(pipeline)
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, env.ctx.main_framebuffer)
		bindFramebufferTexture(pipeline, "g_buffer", 3, env.ctx.texture_uniform)
		drawQuad(pipeline, 0, 0, 1, 1, env.ctx.godrays_material)
end