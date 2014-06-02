import bpy
import struct
import mathutils
import math

def write_indices(f, o, mesh, face, index, offset):
	f.write(struct.pack("I", face.vertices[index] + offset))
	

def write_some_data(context, filepath, use_some_setting):
	print(filepath)
	f = open(filepath, 'wb')
	meshes = []
	vertex_count = 0
	face_count = 0
	for o in context.selected_objects:
		if o.type == 'MESH':
			m = o.to_mesh(context.scene, False, 'PREVIEW')
			meshes.append(m)
			vertex_count += len(m.vertices)
			for face in m.tessfaces:
				if len(face.vertices) == 3:
					face_count += 1;
				if len(face.vertices) == 4:
					face_count += 2;
	
	m = None
	f.write(struct.pack("I", vertex_count));
	offsets = [0]
	for m in meshes:
		for v in m.vertices:
			f.write(struct.pack("f", v.co.x))
			f.write(struct.pack("f", v.co.z))
			f.write(struct.pack("f", -v.co.y))
		offsets.append(offsets[len(offsets) - 1] + len(m.vertices))

	f.write(struct.pack("I", face_count * 3))
	i = 0
	for m in meshes:
		offset = offsets[i]
		for face in m.tessfaces:
			if len(face.vertices) == 3:
				write_indices(f, o, m, face, 0, offset);
				write_indices(f, o, m, face, 1, offset);
				write_indices(f, o, m, face, 2, offset);
			if len(face.vertices) == 4:
				write_indices(f, o, m, face, 0, offset);
				write_indices(f, o, m, face, 2, offset);
				write_indices(f, o, m, face, 1, offset);
				write_indices(f, o, m, face, 0, offset);
				write_indices(f, o, m, face, 3, offset);
				write_indices(f, o, m, face, 2, offset);
		++i
	f.close()
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
    filename_ext = ".pda"

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