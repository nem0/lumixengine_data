framebuffers = {
	{
		name = "default",
		width = 1024,
		height = 768,
		renderbuffers = {
			{format = "rgba8"},
			{format = "depth24"}
		}
	},
	{
		name = "shadowmap",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format="r32f"},
			{format = "depth32"}
		}
	}
}

function init(pipeline)
	shadowmap_uniform = createUniform(pipeline, "u_texShadowmap")
	sky_material = loadMaterial(pipeline, "models/sky/sky.mat")
end

function render(pipeline)
	if not cameraExists(pipeline, "main") then
		setPass(pipeline, "MAIN")
			setFramebuffer(pipeline, "default")
			clear(pipeline, "all", 0)

		return
	end

	setPass(pipeline, "SHADOW")         
		setFramebuffer(pipeline, "shadowmap")
		renderShadowmap(pipeline, 1, "main") 

	setPass(pipeline, "MAIN")
		clear(pipeline, "all", 0x000000ff)
		setFramebuffer(pipeline, "default")
		applyCamera(pipeline, "main")
		renderModels(pipeline, 1, false)
		--renderDebugLines(pipeline)
--[[
	setPass(pipeline, "SKY")
		--disableBlending(pipeline)
		drawQuad(pipeline, -1, -1, 2, 2, sky_material);
		
	setPass(pipeline, "POINT_LIGHT")
		enableBlending(pipeline)
		applyCamera(pipeline, "main")
		renderModels(pipeline, 1, true)
		disableBlending(pipeline)
]]--
end
