framebuffers = {
}
 
function init(pipeline)
end
 
 
function render(pipeline)
		setPass(pipeline, "IMGUI")
			setFramebuffer(pipeline, "default")
			clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x303030ff)
end
