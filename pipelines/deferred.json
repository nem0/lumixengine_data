{
"frame_buffers" : [
	{
		"name" : "main_framebuffer",
		"width" : 1024,
		"height" : 1024,
		"color_buffers_count" : 3,
		"is_depth_buffer" : true
	},
	{
		"name" : "shadowmap",
		"width" : 2048,
		"height" : 2048,
		"color_buffers_count" : 0,
		"is_depth_buffer" : true
	}
],
"commands" : [
	"set_pass", "SHADOW",
	"render_shadowmap", 1, "editor",
	"bind_shadowmap",

	"set_pass", "DEFERRED",
	"bind_framebuffer", "main_framebuffer",
	"apply_camera", "editor", 
	"clear", "all",
	"polygon_mode", true,
	"render_models", 1,
	"render_debug_lines",
	
	"clear", "depth",
	"custom", "render_gizmos",
	"render_debug_texts",
	"unbind_framebuffer",
	
	"set_pass", "MAIN",
	"bind_framebuffer_texture", "shadowmap", 0, 0,
	"bind_framebuffer_texture", "main_framebuffer", 0, 1,
	"bind_framebuffer_texture", "main_framebuffer", 1, 2,
	"bind_framebuffer_texture", "main_framebuffer", 2, 3,
	"clear", "all",
	"apply_camera", "editor",
	"draw_screen_quad", 
	-1, -1, 0, 0, 
	1, -1, 1, 0, 
	1, 1, 1, 1, 
	-1, 1, 0, 1, 
	"models/editor/visualize_shadowmap.mat",
	
	"apply_camera", "editor", 
	"bind_framebuffer_texture", "main_framebuffer", 0, 1,
	"bind_framebuffer_texture", "main_framebuffer", 1, 2,
	"bind_framebuffer_texture", "main_framebuffer", 2, 3,
	"deferred_point_light_loop", "models/editor/point_light_deferred.mat"
	]
}
