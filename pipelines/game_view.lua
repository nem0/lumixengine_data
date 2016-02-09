framebuffers = {
	{
		name = "default",
		width = 1024,
		height = 768,
		renderbuffers = {
			{format = "rgba8"},
		}
	},
	{
		name = "hdr",
		width = 1024,
		height = 768,
		screen_size = true,
		renderbuffers = {
			{format = "rgba16f"},
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
	},
	
		{
		name = "blur",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format = "r32f"}
		}
	},
}

function init(pipeline)
	shadowmap_uniform = createUniform(pipeline, "u_texShadowmap")
	blur_material = loadMaterial(pipeline, "shaders/blur.mat")
	hdr_buffer_uniform = createUniform(pipeline, "u_hdrBuffer")
	hdr_material = loadMaterial(pipeline, "shaders/hdr.mat")
end


function hdr(pipeline)
	setPass(pipeline, "HDR")
		setFramebuffer(pipeline, "default")
		applyCamera(pipeline, "editor")
		clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0xbbd3edff)
		bindFramebufferTexture(pipeline, "hdr", 0, hdr_buffer_uniform)
		drawQuad(pipeline, -1, 1, 2, -2, hdr_material)
end

function render(pipeline)
	if not cameraExists(pipeline, "main") then
		setPass(pipeline, "MAIN")
			setFramebuffer(pipeline, "default")
			clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0xbbd3edff)

		return
	end

	setPass(pipeline, "SHADOW")         
		setFramebuffer(pipeline, "shadowmap")
		renderShadowmap(pipeline, 1, "main") 

	if true then
		setPass(pipeline, "BLUR_H")
			setFramebuffer(pipeline, "blur")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)
			drawQuad(pipeline, -1, -1, 2, 2, blur_material)
			enableDepthWrite(pipeline)
		
		setPass(pipeline, "BLUR_V")
			setFramebuffer(pipeline, "shadowmap")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "blur", 0, shadowmap_uniform)
			drawQuad(pipeline, -1, -1, 2, 2, blur_material);
			enableDepthWrite(pipeline)
	end
		
	setPass(pipeline, "MAIN")
		clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0xbbd3edff)
		setFramebuffer(pipeline, "hdr")
		applyCamera(pipeline, "main")
		renderModels(pipeline, 1, false)
		
	hdr(pipeline)
end
