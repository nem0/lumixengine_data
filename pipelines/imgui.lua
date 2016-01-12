framebuffers = {
}
 
function init(pipeline)
end
 
 
function render(pipeline)
		setPass(pipeline, "IMGUI")
			setFramebuffer(pipeline, "default")
			clear(pipeline, "all", 0x303030ff)
end
