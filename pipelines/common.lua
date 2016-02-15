parameters = { 
	particles_enabled = true,
	render_gizmos = true
}

local current_lum1 = "lum1a"
local lum_uniforms = {}

function computeLumUniforms()
	local sizes = {64, 16, 4, 1 }
	for key,value in ipairs(sizes) do
		lum_uniforms[value] = {}
		for j = 0,3 do
			for i = 0,3 do
				local x = (i) / value; 
				local y = (j) / value; 
				lum_uniforms[value][1 + i + j * 4] = {x, y, 0, 0}
			end
		end
	end

	lum_uniforms[128] = {}
	for j = 0,1 do
		for i = 0,1 do
			local x = i / 128; 
			local y = j / 128; 
			lum_uniforms[128][1 + i + j * 4] = {x, y, 0, 0}
		end
	end
end

function editor()
	if parameters.render_gizmos then
		setPass(this, "EDITOR")
			setFramebuffer(this, "default")
			disableDepthWrite(this)
			disableBlending(this)
			applyCamera(this, "editor")
			renderIcons(this)

		beginNewView(this, "gizmo")
			setFramebuffer(this, "default")
			applyCamera(this, "editor")
			renderGizmos(this)
	end
end

function shadowmapDebug()
	if parameters.render_shadowmap_debug then
		setPass(this, "SCREEN_SPACE")
		beginNewView(this, "SHADOWMAP_DEBUG")
		setFramebuffer(this, "default")
		bindFramebufferTexture(this, "shadowmap", 0, texture_uniform)
		drawQuad(this, 0.48, 0.98, 0.5, -0.5, screen_space_material);
	end
end

function initShadowmap()
	addFramebuffer(this, "shadowmap", {
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format="r32f"},
			{format = "depth32"}
		}
	})

	addFramebuffer(this, "point_light_shadowmap", {
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth32"}
		}
	})

	addFramebuffer(this, "point_light2_shadowmap", {
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth32"}
		}
	})
	parameters.blur_shadowmap = true
	parameters.render_shadowmap_debug = false
end


function initHDR()
	addFramebuffer(this,  "lum128", {
		width = 128,
		height = 128,
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
		screen_size = true;
		renderbuffers = {
			{ format = "rgba16f" },
			{ format = "depth32" }
		}
	})

	computeLumUniforms()
	hdr_exposure_uniform = createVec4ArrayUniform(this, "exposure", 1)
end


function hdr()
	setPass(this, "HDR_LUMINANCE")
		setFramebuffer(this, "lum128")
		disableDepthWrite(this)
		disableBlending(this)
		setUniform(this, lum_size_uniform, lum_uniforms[128])
		bindFramebufferTexture(this, "hdr", 0, hdr_buffer_uniform)
		drawQuad(this, -1, -1, 2, 2, lum_material)
	
	setPass(this, "HDR_AVG_LUMINANCE")
		setFramebuffer(this, "lum64")
		setUniform(this, lum_size_uniform, lum_uniforms[64])
		bindFramebufferTexture(this, "lum128", 0, hdr_buffer_uniform)
		drawQuad(this, -1, -1, 2, 2, lum_material)

	beginNewView(this, "lum16")
		setFramebuffer(this, "lum16")
		setUniform(this, lum_size_uniform, lum_uniforms[16])
		bindFramebufferTexture(this, "lum64", 0, hdr_buffer_uniform)
		drawQuad(this, -1, -1, 2, 2, lum_material)
	
	beginNewView(this, "lum4")
		setFramebuffer(this, "lum4")
		setUniform(this, lum_size_uniform, lum_uniforms[4])
		bindFramebufferTexture(this, "lum16", 0, hdr_buffer_uniform)
		drawQuad(this, -1, -1, 2, 2, lum_material)

	local old_lum1 = "lum1b"
	if current_lum1 == "lum1a" then 
		current_lum1 = "lum1b" 
		old_lum1 = "lum1a"
	else 
		current_lum1 = "lum1a" 
	end

	setPass(this, "LUM1")
		setFramebuffer(this, current_lum1)
		setUniform(this, lum_size_uniform, lum_uniforms[1])
		bindFramebufferTexture(this, "lum4", 0, hdr_buffer_uniform)
		bindFramebufferTexture(this, old_lum1, 0, avg_luminance_uniform)
		drawQuad(this, -1, -1, 2, 2, lum_material)

	setPass(this, "HDR")
		setFramebuffer(this, "default")
		disableBlending(this)
		applyCamera(this, "editor")
		disableDepthWrite(this)
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
		bindFramebufferTexture(this, "hdr", 0, hdr_buffer_uniform)
		bindFramebufferTexture(this, current_lum1, 0, avg_luminance_uniform)

		local hdr_exposure = {getRenderParamFloat(this, hdr_exposure_param), 0, 0, 0}
 		setUniform(this, hdr_exposure_uniform, {hdr_exposure})
		
		drawQuad(this, -1, 1, 2, -2, hdr_material)
end

function shadowmap()
	setPass(this, "SHADOW")         
		applyCamera(this, "editor")
		setFramebuffer(this, "shadowmap")
		renderShadowmap(this, 1) 
	
	if parameters.blur_shadowmap then
		setPass(this, "BLUR_H")
			setFramebuffer(this, "blur")
			disableDepthWrite(this)
			bindFramebufferTexture(this, "shadowmap", 0, shadowmap_uniform)
			drawQuad(this, -1, -1, 2, 2, blur_material)
			enableDepthWrite(this)
		
		setPass(this, "BLUR_V")
			setFramebuffer(this, "shadowmap")
			disableDepthWrite(this)
			bindFramebufferTexture(this, "blur", 0, shadowmap_uniform)
			drawQuad(this, -1, -1, 2, 2, blur_material);
			enableDepthWrite(this)
	end
end

function particles()
	if parameters.particles_enabled then
		setPass(this, "PARTICLES")
		disableDepthWrite(this)
		applyCamera(this, "editor")
		renderParticles(this)
	end	
end
