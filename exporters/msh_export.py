import bpy
import struct
import mathutils
import math
import os
from bpy_extras.io_utils import (ExportHelper,
                                 axis_conversion,
                                 )

SZ_SHORT = 2
SZ_INT = 4
SZ_FLOAT = 4

swap_y_z_matrix = axis_conversion('Y', 'Z', '-Z', 'Y').to_4x4()

class TriWrapper(object):
    __slots__ = "vertex_index", "mat", "image", "faceuvs", "offset"

    def __init__(self, vindex=(0, 0, 0), mat=None, image=None, faceuvs=None):
        self.vertex_index = vindex
        self.mat = mat
        self.image = image
        self.faceuvs = faceuvs
        self.offset = [0, 0, 0]  # offset indices

class Point3D(object):
    __slots__ = "x", "y", "z", "nx", "ny", "nz", "w", "tx", "ty", "tz"

    def __init__(self, point, normal, tangent):
        self.x, self.y, self.z = point
        self.nx, self.ny, self.nz = normal
        self.tx, self.ty, self.tz = tangent
        self.w = None


class PointUV(object):
    __slots__ = ("uv", )

    def __init__(self, point):
        self.uv = point

    def get_size(self):
        return 2 * SZ_FLOAT

    def write(self, file):
        data = struct.pack('<2f', self.uv[0], self.uv[1])
        file.write(data)

    def __str__(self):
        return '(%g, %g)' % self.uv

def UVKey(uv):
    return round(uv[0], 6), round(uv[1], 6)

def extract_tangents(mesh):
    tangents = []
    for i in range(len(mesh.vertices)):
        tangents.append([0, mathutils.Vector()])

    for l in mesh.loops:
        i = l.vertex_index
        tangents[i][0] = tangents[i][0] + 1
        tangents[i][1] = tangents[i][1] + l.tangent

    tmp = []
    for t in tangents:
        tmp.append(t[1] / t[0])
    
    return tmp
    
def extract_triangles(mesh):
    tri_list = []
    do_uv = bool(mesh.tessface_uv_textures)

    img = None
    for i, face in enumerate(mesh.tessfaces):
        f_v = face.vertices

        uf = mesh.tessface_uv_textures.active.data[i] if do_uv else None

        if do_uv:
            f_uv = uf.uv
            img = uf.image if uf else None
            if img is not None:
                img = img.name

        # if f_v[3] == 0:
        if len(f_v) == 3:
            new_tri = TriWrapper((f_v[0], f_v[1], f_v[2]), face.material_index, img)
            if (do_uv):
                new_tri.faceuvs = UVKey(f_uv[0]), UVKey(f_uv[1]), UVKey(f_uv[2])
            tri_list.append(new_tri)

        else:  # it's a quad
            new_tri = TriWrapper((f_v[0], f_v[1], f_v[2]), face.material_index, img)
            new_tri_2 = TriWrapper((f_v[0], f_v[2], f_v[3]), face.material_index, img)

            if (do_uv):
                new_tri.faceuvs = UVKey(f_uv[0]), UVKey(f_uv[1]), UVKey(f_uv[2])
                new_tri_2.faceuvs = UVKey(f_uv[0]), UVKey(f_uv[2]), UVKey(f_uv[3])

            tri_list.append(new_tri)
            tri_list.append(new_tri_2)

    return tri_list

def remove_face_uv(mesh, verts, tri_list):
    unique_uvs = [{} for i in range(len(verts))]

    for tri in tri_list:
        for i in range(3):

            context_uv_vert = unique_uvs[tri.vertex_index[i]]
            uvkey = tri.faceuvs[i]

            offset_index__uv_3ds = context_uv_vert.get(uvkey)

            if not offset_index__uv_3ds:
                offset_index__uv_3ds = context_uv_vert[uvkey] = len(context_uv_vert), PointUV(uvkey)

            tri.offset[i] = offset_index__uv_3ds[0]

    vert_index = 0
    vert_array = []
    uv_array = []
    index_list = []
    tangents = extract_tangents(mesh)

    for i, vert in enumerate(verts):
        index_list.append(vert_index)

        pt = Point3D(vert.co, vert.normal, tangents[vert.index])
        uvmap = [None] * len(unique_uvs[i])
        for ii, uv_3ds in unique_uvs[i].values():
            vert_array.append(pt)
            uvmap[ii] = uv_3ds

        for uv_3ds in uvmap:
            uv_array.append(uv_3ds)

        vert_index += len(unique_uvs[i])

    for tri in tri_list:
        for i in range(3):
            tri.offset[i] += index_list[tri.vertex_index[i]]
        tri.vertex_index = tri.offset

    return vert_array, uv_array, tri_list

    
def remove_face_uv_skinned(mesh, verts, tri_list, bone_indices, o):
    unique_uvs = [{} for i in range(len(verts))]

    for tri in tri_list:
        for i in range(3):
            context_uv_vert = unique_uvs[tri.vertex_index[i]]
            uvkey = tri.faceuvs[i]

            offset_index__uv_3ds = context_uv_vert.get(uvkey)

            if not offset_index__uv_3ds:
                offset_index__uv_3ds = context_uv_vert[uvkey] = len(context_uv_vert), PointUV(uvkey)

            tri.offset[i] = offset_index__uv_3ds[0]

    vert_index = 0
    vert_array = []
    uv_array = []
    index_list = []
    tangents = extract_tangents(mesh)
    
    for i, vert in enumerate(verts):
        index_list.append(vert_index)

        pt = Point3D(vert.co, vert.normal, tangets[vert.index])  # reuse, should be ok
        uvmap = [None] * len(unique_uvs[i])
        for ii, uv_3ds in unique_uvs[i].values():
            pt.w = compute_weights(vert, bone_indices, o.vertex_groups, len(o.vertex_groups))
            vert_array.append(pt)
            
            uvmap[ii] = uv_3ds

        for uv_3ds in uvmap:
            uv_array.append(uv_3ds)

        vert_index += len(unique_uvs[i])

    for tri in tri_list:
        for i in range(3):
            tri.offset[i] += index_list[tri.vertex_index[i]]
        tri.vertex_index = tri.offset

    return vert_array, uv_array, tri_list

    
    
def compute_weights(v, bone_indices, groups, groups_count):
    w = []
    for g in v.groups:
        if g.group < groups_count and groups[g.group].name in bone_indices:
            w.append([g.weight, groups[g.group].name, bone_indices[groups[g.group].name]])
        else:
            print("group not found " + str(g.group) + " " + groups[g.group].name);
    if len(w) == 0:
        w.append([1.0, groups[0].name, bone_indices[groups[0].name]])
        print("vertex with no weights");
    w.sort(key = lambda m : -m[0])
    w = w[:4]
    for i in range(len(w), 4):
        w.append([0.0, "", 0])
    s = sum([x[0] for x in w])
    if s > 0:
        for x in w:
            x[0] = x[0] / s
    return w

def write_indices(f, o, mesh, face, index):
    f.write(struct.pack("I", face.vertices[index]))
    
def write_str(f, str):
    l = len(str)
    f.write(struct.pack("I", l))
    f.write(bytes(str, "ascii"))
    return

def calc_tangent_bitangent(f, out):
    edge1 = f.v[1].co - f.v[0].co
    edge2 = f.v[2].co - f.v[0].co
    edge1uv = f.uv[1] - f.uv[0]
    edge2uv = f.uv[2] - f.uv[0]

    cp = edge1uv.y * edge2uv.x - edge1uv.x * edge2uv.y;

    if(cp != 0.0):
        mul = 1.0 / cp;
    tangent = (edge1 * -edge2uv.y + edge2 * edge1uv.y) * mul
    bitangent = (edge1 * -edge2uv.x + edge2 * edge1uv.x) * mul    
    return tangent, bitangent
    
def write_physics(f, o, context):
    shapes = ["cube", "convex", "trimesh"]
    f.write(struct.pack("I", shapes.index(o["physics"])))
    if o["physics"] == "cube":
        f.write(struct.pack("f", o.matrix_local.to_scale().x))
        f.write(struct.pack("f", o.matrix_local.to_scale().z))
        f.write(struct.pack("f", o.matrix_local.to_scale().y))
    elif o["physics"] == "convex":
        m = o.to_mesh(context.scene, False, 'PREVIEW')
        f.write(struct.pack("I", len(m.vertices)));
        for v in m.vertices:
            f.write(struct.pack("f", v.co.x))
            f.write(struct.pack("f", v.co.y))
            f.write(struct.pack("f", v.co.z))
    elif o["physics"] == "trimesh":
        m = o.to_mesh(context.scene, False, 'PREVIEW')
        f.write(struct.pack("I", len(m.vertices)));
        for v in m.vertices:
            f.write(struct.pack("f", v.co.x))
            f.write(struct.pack("f", v.co.y))
            f.write(struct.pack("f", v.co.z))
        face_count = 0
        for face in m.tessfaces:
            if len(face.vertices) == 3:
                face_count += 1;
            if len(face.vertices) == 4:
                face_count += 2;
        f.write(struct.pack("I", face_count * 3))
        for face in m.tessfaces:
            if len(face.vertices) == 3:
                write_indices(f, o, m, face, 0);
                write_indices(f, o, m, face, 1);
                write_indices(f, o, m, face, 2,);
            if len(face.vertices) == 4:
                write_indices(f, o, m, face, 0);
                write_indices(f, o, m, face, 2);
                write_indices(f, o, m, face, 1);
                write_indices(f, o, m, face, 0);
                write_indices(f, o, m, face, 3);
                write_indices(f, o, m, face, 2);
                

def write_skeleton(f, armature):
    bone_count = len(armature.data.bones)
    f.write(struct.pack("I", bone_count))    
    for b in armature.data.bones:
        write_str(f, b.name)
        if b.parent == None:
            write_str(f, "")
            mtx = armature.matrix_world * b.matrix_local;
        else:
            write_str(f, b.parent.name)
            mtx = armature.matrix_world * b.matrix_local;
        mtx = swap_y_z_matrix * mtx
        p = mtx.translation;
        f.write(struct.pack("f", round(p.x, 8)))
        f.write(struct.pack("f", round(p.y, 8)))
        f.write(struct.pack("f", round(p.z, 8)))
        q = mtx.to_quaternion()
        f.write(struct.pack("f", round(q.x, 8)))
        f.write(struct.pack("f", round(q.y, 8)))
        f.write(struct.pack("f", round(q.z, 8)))
        f.write(struct.pack("f", round(q.w, 8)))


def write_model_header(f):
    f.write(bytes("OML_", "ascii"))
    f.write(struct.pack("I", 1))
        
def write_skinned_model_indexed(context, f, armature, objs_to_export):
    write_model_header(f)
    meshes = []
    face_counts = []
    face_counts.append(0)
    face_count = 0
    vertex_size = 56
    indices = []
    vertices = []
    vertex_attributes_offsets = []
    vertex_attributes_offsets.append(0)
    bone_indices = {}
    bone_index = 0
    uvs = []
    index_base = 0
    max_idx = 0;
    attr_offset = 0;
    for b in armature.data.bones:
        bone_indices[b.name] = bone_index;
        bone_index = bone_index + 1
    for o in objs_to_export:
        m = o.to_mesh(context.scene, False, 'PREVIEW')
        m.transform(swap_y_z_matrix * o.matrix_world)
        meshes.append(m)
        tri_list = extract_triangles(m)
        if m.tessface_uv_textures:
            vert_array, uv_array, tri_list = remove_face_uv_skinned(m, m.vertices, tri_list, bone_indices, o)
        else:
            print("error");
            
        for tri in tri_list:
            indices += [tri.vertex_index[0] + index_base, tri.vertex_index[1] + index_base, tri.vertex_index[2] + index_base]
        face_count += len(tri_list)
        face_counts.append(face_count)
        attr_offset += len(vert_array) * vertex_size
        vertex_attributes_offsets.append(attr_offset)
        vertices += vert_array
        uvs += uv_array
        index_base = len(vertices)    
        index_base = 0
    
    index = 0
    f.write(struct.pack("I", len(objs_to_export)))   
    for m in meshes:
        if m == None:
            material = ""
            f.write(struct.pack("I", len(material)))
            f.write(bytes(material, "ascii"))
        else:
            material = m.materials[0].name
            f.write(struct.pack("I", len(material)))
            f.write(bytes(material, "ascii"))

        f.write(struct.pack("I", vertex_attributes_offsets[index]))
        f.write(struct.pack("I", vertex_attributes_offsets[index + 1] - vertex_attributes_offsets[index]))
        f.write(struct.pack("I", face_counts[index] * 3))
        if index == 0:
            f.write(struct.pack("I", face_counts[index + 1]))
        else:
            f.write(struct.pack("I", face_counts[index + 1] - face_counts[index]))
        f.write(struct.pack("I", len(objs_to_export[index].name)))
        f.write(bytes(objs_to_export[index].name, "ascii"))
        index = index + 1
    
        f.write(struct.pack("I", 11))
        f.write(bytes("f4i4pb4b4s2", "ascii"))
    
    f.write(struct.pack("I", len(indices)))
    for i in indices:
        f.write(struct.pack("I", i))

    f.write(struct.pack("I", len(vertices) * vertex_size))
    
    for v, uv in zip(vertices, uvs):
        f.write(struct.pack("f", v.w[0][0]))
        f.write(struct.pack("f", v.w[1][0]))
        f.write(struct.pack("f", v.w[2][0]))
        f.write(struct.pack("f", v.w[3][0]))
        f.write(struct.pack("I", v.w[0][2]))
        f.write(struct.pack("I", v.w[1][2]))
        f.write(struct.pack("I", v.w[2][2]))
        f.write(struct.pack("I", v.w[3][2]))
        f.write(struct.pack("f", v.x))
        f.write(struct.pack("f", v.y))
        f.write(struct.pack("f", v.z))
        f.write(struct.pack("b", int(v.nx * 127)))
        f.write(struct.pack("b", int(v.ny * 127)))
        f.write(struct.pack("b", int(v.nz * 127)))
        f.write(struct.pack("b", 0))
        f.write(struct.pack("b", int(v.tx * 127)))
        f.write(struct.pack("b", int(v.ty * 127)))
        f.write(struct.pack("b", int(v.tz * 127)))
        f.write(struct.pack("b", 0))
        f.write(struct.pack("h", int(uv.uv[0] * 2048)))
        f.write(struct.pack("h", int(uv.uv[1] * 2048)))

    write_skeleton(f, armature)

    return meshes

    
def write_rigid_model_indexed(context, f, objs_to_export, is_grass):
    write_model_header(f)
    meshes = []
    face_counts = []
    face_counts.append(0)
    face_count = 0
    vertex_size = 24
    if is_grass:
        vertex_size = 28
    indices = []
    vertices = []
    vertex_attributes_offsets = []
    vertex_attributes_offsets.append(0)
    uvs = []
    index_base = 0
    max_idx = 0;
    attr_offset = 0;
    for o in objs_to_export:
        m = o.to_mesh(context.scene, False, 'PREVIEW')
        m.transform(swap_y_z_matrix * o.matrix_world)
        m.calc_normals()
        meshes.append(m)
        tri_list = extract_triangles(m)
        if m.tessface_uv_textures:
            vert_array, uv_array, tri_list = remove_face_uv(m, m.vertices, tri_list)
        else:
            print("error");
            
        for tri in tri_list:
            indices += [tri.vertex_index[0] + index_base, tri.vertex_index[1] + index_base, tri.vertex_index[2] + index_base]
        face_count += len(tri_list)
        face_counts.append(face_count)
        attr_offset += len(vert_array) * vertex_size
        vertex_attributes_offsets.append(attr_offset)
        vertices += vert_array
        uvs += uv_array
        index_base = len(vertices)    
        index_base = 0
    
    index = 0
    f.write(struct.pack("I", len(objs_to_export)))   
    for m in meshes:
        if m == None:
            material = ""
            f.write(struct.pack("I", len(material)))
            f.write(bytes(material, "ascii"))
        else:
            material = m.materials[0].name
            f.write(struct.pack("I", len(material)))
            f.write(bytes(material, "ascii"))

        f.write(struct.pack("I", vertex_attributes_offsets[index]))
        f.write(struct.pack("I", vertex_attributes_offsets[index + 1] - vertex_attributes_offsets[index]))
        f.write(struct.pack("I", face_counts[index] * 3))
        if index == 0:
            f.write(struct.pack("I", face_counts[index + 1]))
        else:
            f.write(struct.pack("I", face_counts[index + 1] - face_counts[index]))
        f.write(struct.pack("I", len(objs_to_export[index].name)))
        f.write(bytes(objs_to_export[index].name, "ascii"))
        index = index + 1
    
        if is_grass:
            f.write(struct.pack("I", 9))
            f.write(bytes("pb4b4s2i1", "ascii"))
        else:
            f.write(struct.pack("I", 7))
            f.write(bytes("pb4b4s2", "ascii"))
    
    f.write(struct.pack("I", len(indices)))
    for i in indices:
        f.write(struct.pack("I", i))
    
    f.write(struct.pack("I", len(vertices) * vertex_size))
        
    for v, uv in zip(vertices, uvs):
        f.write(struct.pack("f", v.x))
        f.write(struct.pack("f", v.y))
        f.write(struct.pack("f", v.z))
        f.write(struct.pack("b", int(v.nx * 127)))
        f.write(struct.pack("b", int(v.ny * 127)))
        f.write(struct.pack("b", int(v.nz * 127)))
        f.write(struct.pack("b", 0))
        f.write(struct.pack("b", int(v.tx * 127)))
        f.write(struct.pack("b", int(v.ty * 127)))
        f.write(struct.pack("b", int(v.tz * 127)))
        f.write(struct.pack("b", 0))
        f.write(struct.pack("h", int(uv.uv[0] * 2048)))
        f.write(struct.pack("h", int(uv.uv[1] * 2048)))
        if is_grass:
            f.write(struct.pack("I", 1)) # just a placeholder

    bone_count = 0
    f.write(struct.pack("I", bone_count))  
    
    lod_count = 1
    f.write(struct.pack("I", lod_count))
    to_mesh = len(meshes) - 1
    f.write(struct.pack("i", to_mesh))
    f.write(struct.pack("f", sys.float_info.max))
    
    return meshes

def export_material(base_path, material, shader):
    path = base_path + "/" + material + ".mat"
    print("Exporting material " + path)    
    f_mat = open(path, "w");
    f_mat.write("{ \"texture\" : { \"source\" : \"" + material + ".dds\" }, \"shader\" : \"shaders/" + shader + ".shd\" }");
    f_mat.close();
        
def add_meshes(objs, o):
    for i in o.children:
        if i.type == 'MESH':
            objs.append(i)
        
def export_model(context, filepath, export_materials, is_grass, export_selection):
    print(filepath)
    f = open(filepath, 'wb')
    objs = []
    if export_selection:
        armature = context.selected_objects[0].find_armature()
        for o in context.selected_objects:
            if o.type == 'MESH':
                objs.append(o)
            else:
                add_meshes(objs, o)
    else:
        for o in context.scene.objects:
            if o.type == 'MESH':
                objs.append(o)
            else:
                add_meshes(objs, o)
        armature = objs[0].find_armature()
    object_count = len(objs)
    print("object_count")
    print(object_count)
        
    objs = sorted(objs, key = lambda x: x.name[x.name.find('_LOD') + 4])
    shader = "rigid"
    if armature != None:
        shader = "skinned"
        meshes = write_skinned_model_indexed(context, f, armature, objs)
    else:
        meshes = write_rigid_model_indexed(context, f, objs, is_grass)
    print("shader " + shader)
    
    base_path = os.path.dirname(filepath)
    if export_materials:
        for m in meshes:
            export_material(base_path, m.materials[0].name, shader)
    
    phy_object_count = 0
    for o in context.scene.objects:
        if "physics" in o:
            phy_object_count = phy_object_count + 1
    f.write(struct.pack("I", phy_object_count))
    for o in context.scene.objects:
        if "physics" in o:
            write_physics(f, o, context)
    f.close()
    return {'FINISHED'}


# ExportHelper is a helper class, defines filename and
# invoke() function which calls the file selector.
from bpy_extras.io_utils import ExportHelper
from bpy.props import StringProperty, BoolProperty, EnumProperty
from bpy.types import Operator


class LumixExporter(Operator, ExportHelper):
    bl_idname = "export_scene.lumix_msh"
    bl_label = "Export Lumix Engine Mesh"

    filename_ext = ".msh"
    filter_glob = StringProperty(default="*.msh", options={'HIDDEN'})

    is_grass = BoolProperty(
        name="Is mesh grass",
        description="Export mesh in grass format",
        default=False,
        )
    
    export_materials = BoolProperty(
            name="Export Materials",
            description="Export Materials",
            default=False,
            )

    def execute(self, context):
        return export_model(context, self.filepath, self.export_materials, self.is_grass, True)


def menu_func_export(self, context):
    self.layout.operator(LumixExporter.bl_idname, text="Lumix Mesh (*.msh)")


def register():
    bpy.utils.register_class(LumixExporter)
    bpy.types.INFO_MT_file_export.append(menu_func_export)


def unregister():
    bpy.utils.unregister_class(LumixExporter)
    bpy.types.INFO_MT_file_export.remove(menu_func_export)

bl_info = {
    "name": "Lumix Mesh exporter",
    "description": "Export mesh file in the Lumix engine file format",
    "author": "Mikulas Florek",
    "version": (1, 0),
    "blender": (2, 72, 0),
    "location": "File > Export",
    "warning": "", # used for warning icon and text in addons panel
    "wiki_url": "http://wiki.blender.org/index.php/Extensions:2.5/Py/"
                "Scripts/My_Script",
    "category": "Import-Export"}
    
import sys
if __name__ == "__main__":
    if(len(sys.argv) == 7):
        export_model(bpy.context, sys.argv[6], False, False, True);
    else:
        register()
