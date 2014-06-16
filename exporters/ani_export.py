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

def write_some_data(context, filepath, use_some_setting):

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
				mtx = swap_y_z_matrix * o.matrix_world * pose_bone.matrix;
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
				mtx = swap_y_z_matrix * o.matrix_world * pose_bone.matrix;
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
			print(str(q.x) + " " + str(q.y) + " " + str(q.z) );
			bone_idx = bone_idx + 1;	
	return {'FINISHED'}


# ExportHelper is a helper class, defines filename and
# invoke() function which calls the file selector.
from bpy_extras.io_utils import ExportHelper
from bpy.props import StringProperty, BoolProperty, EnumProperty
from bpy.types import Operator


class ExportSomeData(Operator, ExportHelper):
    """This appears in the tooltip of the operator and in the generated docs"""
    bl_idname = "export_test.some_data"  # important since its how bpy.ops.import_test.some_data is constructed
    bl_label = "Export Some Data"

    # ExportHelper mixin class uses this
    filename_ext = ".ani"

    filter_glob = StringProperty(
            default="*.txt",
            options={'HIDDEN'},
            )

    # List of operator properties, the attributes will be assigned
    # to the class instance from the operator settings before calling.
    use_setting = BoolProperty(
            name="Example Boolean",
            description="Example Tooltip",
            default=True,
            )

    type = EnumProperty(
            name="Example Enum",
            description="Choose between two items",
            items=(('OPT_A', "First Option", "Description one"),
                   ('OPT_B', "Second Option", "Description two")),
            default='OPT_A',
            )

    def execute(self, context):
        return write_some_data(context, self.filepath, self.use_setting)


# Only needed if you want to add into a dynamic menu
def menu_func_export(self, context):
    self.layout.operator(ExportSomeData.bl_idname, text="Text Export Operator")


def register():
    bpy.utils.register_class(ExportSomeData)
    bpy.types.INFO_MT_file_export.append(menu_func_export)


def unregister():
    bpy.utils.unregister_class(ExportSomeData)
    bpy.types.INFO_MT_file_export.remove(menu_func_export)


if __name__ == "__main__":
    register()

    # test call
    bpy.ops.export_test.some_data('INVOKE_DEFAULT')