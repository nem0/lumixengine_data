import bpy
import struct
import mathutils
import math
from bpy_extras.io_utils import (ExportHelper,
									axis_conversion,
									)

swap_y_z_matrix = axis_conversion('Y', 'Z', '-Z', 'Y').to_4x4()

def write_str(f, str):
	l = len(str)
	f.write(struct.pack("I", l))
	f.write(bytes(str, "ascii"))
	return

def export_animation(context, filepath):

	f = open(filepath, 'wb')
	o = context.selected_objects[0]
	f.write(struct.pack("I", 0x5f4c4146))
	f.write(struct.pack("I", 1))
	f.write(struct.pack("I", context.scene.frame_end + 1))
	f.write(struct.pack("I", len(o.data.bones)))
	for frame in range(context.scene.frame_end + 1):
		context.scene.frame_set(frame)
		bone_idx = 0
		for pose_bone in o.pose.bones:
			if pose_bone.parent == None:
				mtx = swap_y_z_matrix * o.matrix_world * pose_bone.matrix;
			else:
				mtx = pose_bone.parent.matrix.inverted() * pose_bone.matrix
			p = mtx.translation;
			
			f.write(struct.pack("f", p.x))
			f.write(struct.pack("f", p.y))
			f.write(struct.pack("f", p.z))
			bone_idx = bone_idx + 1;
	first_frame_q = {}
	for frame in range(context.scene.frame_end + 1):
		context.scene.frame_set(frame)
		bone_idx = 0
		for pose_bone in o.pose.bones:
			if pose_bone.parent == None:
				mtx = swap_y_z_matrix * o.matrix_world * pose_bone.matrix;
			else:
				mtx = pose_bone.parent.matrix.inverted() * pose_bone.matrix
			q = mtx.to_quaternion();
			
			if frame == 0:
				first_frame_q[len(first_frame_q)] = q;
			else:
				if q.dot(first_frame_q[bone_idx]) < 0:
					q = -q;
			f.write(struct.pack("f", q.x))
			f.write(struct.pack("f", q.y))
			f.write(struct.pack("f", q.z))
			f.write(struct.pack("f", q.w))
			bone_idx = bone_idx + 1;	
	return {'FINISHED'}


# ExportHelper is a helper class, defines filename and
# invoke() function which calls the file selector.
from bpy_extras.io_utils import ExportHelper
from bpy.props import StringProperty, BoolProperty, EnumProperty
from bpy.types import Operator


class LumixAnimExporter(Operator, ExportHelper):
    bl_idname = "export_scene.lumix_ani"  # important since its how bpy.ops.import_test.some_data is constructed
    bl_label = "Export Lumix Engine Animation"

    # ExportHelper mixin class uses this
    filename_ext = ".ani"

    filter_glob = StringProperty(
            default="*.ani",
            options={'HIDDEN'},
            )

    def execute(self, context):
        return export_animation(context, self.filepath)


# Only needed if you want to add into a dynamic menu
def menu_func_export(self, context):
    self.layout.operator(LumixAnimExporter.bl_idname, text="Lumix Animation (*.ani)")


def register():
    bpy.utils.register_class(LumixAnimExporter)
    bpy.types.INFO_MT_file_export.append(menu_func_export)


def unregister():
    bpy.utils.unregister_class(LumixAnimExporter)
    bpy.types.INFO_MT_file_export.remove(menu_func_export)


bl_info = {
    "name": "Lumix Animation exporter",
    "description": "Export animation file in the Lumix engine file format",
    "author": "Mikulas Florek",
    "version": (1, 0),
    "blender": (2, 68, 0),
    "location": "File > Export",
    "warning": "", # used for warning icon and text in addons panel
    "wiki_url": "http://wiki.blender.org/index.php/Extensions:2.5/Py/"
                "Scripts/My_Script",
    "category": "Import-Export"}
	
import sys
	
if __name__ == "__main__":
	if(len(sys.argv) == 7):
		export_animation(bpy.context, sys.argv[6]);
	else:
		register()
	