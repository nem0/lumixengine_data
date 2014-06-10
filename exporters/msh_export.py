import bpy
import struct
import mathutils
import math
import os

SZ_SHORT = 2
SZ_INT = 4
SZ_FLOAT = 4


class tri_wrapper(object):
    __slots__ = "vertex_index", "mat", "image", "faceuvs", "offset"

    def __init__(self, vindex=(0, 0, 0), mat=None, image=None, faceuvs=None):
        self.vertex_index = vindex
        self.mat = mat
        self.image = image
        self.faceuvs = faceuvs
        self.offset = [0, 0, 0]  # offset indices

class _3ds_point_3d(object):
	"""Class representing a three-dimensional point for a 3ds file."""
	__slots__ = "x", "y", "z", "nx", "ny", "nz", "w"

	def __init__(self, point, normal):
		self.x, self.y, self.z = point
		self.nx, self.ny, self.nz = normal
		self.w = None
		
class _3ds_array(object):
    """Class representing an array of variables for a 3ds file.

    Consists of a _3ds_ushort to indicate the number of items, followed by the items themselves.
    """
    __slots__ = "values"

    def __init__(self):
        self.values = []

    # add an item:
    def add(self, item):
        self.values.append(item)

    def validate(self):
        return len(self.values) <= 65535


class _3ds_point_uv(object):
    """Class representing a UV-coordinate for a 3ds file."""
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
		
def uv_key(uv):
    return round(uv[0], 6), round(uv[1], 6)
		
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
            new_tri = tri_wrapper((f_v[0], f_v[1], f_v[2]), face.material_index, img)
            if (do_uv):
                new_tri.faceuvs = uv_key(f_uv[0]), uv_key(f_uv[1]), uv_key(f_uv[2])
            tri_list.append(new_tri)

        else:  # it's a quad
            new_tri = tri_wrapper((f_v[0], f_v[1], f_v[2]), face.material_index, img)
            new_tri_2 = tri_wrapper((f_v[0], f_v[2], f_v[3]), face.material_index, img)

            if (do_uv):
                new_tri.faceuvs = uv_key(f_uv[0]), uv_key(f_uv[1]), uv_key(f_uv[2])
                new_tri_2.faceuvs = uv_key(f_uv[0]), uv_key(f_uv[2]), uv_key(f_uv[3])

            tri_list.append(new_tri)
            tri_list.append(new_tri_2)

    return tri_list

def remove_face_uv(verts, tri_list):
    """Remove face UV coordinates from a list of triangles.

    Since 3ds files only support one pair of uv coordinates for each vertex, face uv coordinates
    need to be converted to vertex uv coordinates. That means that vertices need to be duplicated when
    there are multiple uv coordinates per vertex."""

    # initialize a list of UniqueLists, one per vertex:
    #uv_list = [UniqueList() for i in xrange(len(verts))]
    unique_uvs = [{} for i in range(len(verts))]

    # for each face uv coordinate, add it to the UniqueList of the vertex
    for tri in tri_list:
        for i in range(3):
            # store the index into the UniqueList for future reference:
            # offset.append(uv_list[tri.vertex_index[i]].add(_3ds_point_uv(tri.faceuvs[i])))

            context_uv_vert = unique_uvs[tri.vertex_index[i]]
            uvkey = tri.faceuvs[i]

            offset_index__uv_3ds = context_uv_vert.get(uvkey)

            if not offset_index__uv_3ds:
                offset_index__uv_3ds = context_uv_vert[uvkey] = len(context_uv_vert), _3ds_point_uv(uvkey)

            tri.offset[i] = offset_index__uv_3ds[0]

    # At this point, each vertex has a UniqueList containing every uv coordinate that is associated with it
    # only once.

    # Now we need to duplicate every vertex as many times as it has uv coordinates and make sure the
    # faces refer to the new face indices:
    vert_index = 0
    vert_array = _3ds_array()
    uv_array = _3ds_array()
    index_list = []
    for i, vert in enumerate(verts):
        index_list.append(vert_index)

        pt = _3ds_point_3d(vert.co, vert.normal)  # reuse, should be ok
        uvmap = [None] * len(unique_uvs[i])
        for ii, uv_3ds in unique_uvs[i].values():
            # add a vertex duplicate to the vertex_array for every uv associated with this vertex:
            vert_array.add(pt)
            # add the uv coordinate to the uv array:
            # This for loop does not give uv's ordered by ii, so we create a new map
            # and add the uv's later
            # uv_array.add(uv_3ds)
            uvmap[ii] = uv_3ds

        # Add the uv's in the correct order
        for uv_3ds in uvmap:
            # add the uv coordinate to the uv array:
            uv_array.add(uv_3ds)

        vert_index += len(unique_uvs[i])

    # Make sure the triangle vertex indices now refer to the new vertex list:
    for tri in tri_list:
        for i in range(3):
            tri.offset[i] += index_list[tri.vertex_index[i]]
        tri.vertex_index = tri.offset

    return vert_array, uv_array, tri_list

	
def remove_face_uv_skinned(verts, tri_list, bone_indices, o):
    """Remove face UV coordinates from a list of triangles.

    Since 3ds files only support one pair of uv coordinates for each vertex, face uv coordinates
    need to be converted to vertex uv coordinates. That means that vertices need to be duplicated when
    there are multiple uv coordinates per vertex."""

    # initialize a list of UniqueLists, one per vertex:
    #uv_list = [UniqueList() for i in xrange(len(verts))]
    unique_uvs = [{} for i in range(len(verts))]

    # for each face uv coordinate, add it to the UniqueList of the vertex
    for tri in tri_list:
        for i in range(3):
            # store the index into the UniqueList for future reference:
            # offset.append(uv_list[tri.vertex_index[i]].add(_3ds_point_uv(tri.faceuvs[i])))

            context_uv_vert = unique_uvs[tri.vertex_index[i]]
            uvkey = tri.faceuvs[i]

            offset_index__uv_3ds = context_uv_vert.get(uvkey)

            if not offset_index__uv_3ds:
                offset_index__uv_3ds = context_uv_vert[uvkey] = len(context_uv_vert), _3ds_point_uv(uvkey)

            tri.offset[i] = offset_index__uv_3ds[0]

    # At this point, each vertex has a UniqueList containing every uv coordinate that is associated with it
    # only once.

    # Now we need to duplicate every vertex as many times as it has uv coordinates and make sure the
    # faces refer to the new face indices:
    vert_index = 0
    vert_array = _3ds_array()
    uv_array = _3ds_array()
    index_list = []
    for i, vert in enumerate(verts):
        index_list.append(vert_index)

        pt = _3ds_point_3d(vert.co, vert.normal)  # reuse, should be ok
        uvmap = [None] * len(unique_uvs[i])
        for ii, uv_3ds in unique_uvs[i].values():
            # add a vertex duplicate to the vertex_array for every uv associated with this vertex:
            pt.w = compute_weights(vert, bone_indices, o.vertex_groups, len(o.vertex_groups))
            vert_array.add(pt)
            
            uvmap[ii] = uv_3ds

        # Add the uv's in the correct order
        for uv_3ds in uvmap:
            # add the uv coordinate to the uv array:
            uv_array.add(uv_3ds)

        vert_index += len(unique_uvs[i])

    # Make sure the triangle vertex indices now refer to the new vertex list:
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


def write_vertex(f, o, mesh, face, index):
	v = mesh.vertices[face.vertices[index]]
	f.write(struct.pack("f", v.co.x))
	f.write(struct.pack("f", v.co.z))
	f.write(struct.pack("f", v.co.y))
	f.write(struct.pack("f", v.normal.x))
	f.write(struct.pack("f", v.normal.z))
	f.write(struct.pack("f", v.normal.y))
	uv = mesh.tessface_uv_textures[0].data[face.index].uv[index][0]
	f.write(struct.pack("f", uv))
	uv = mesh.tessface_uv_textures[0].data[face.index].uv[index][1]
	f.write(struct.pack("f", uv))
	return True

def write_vertex_skinned(f, o, mesh, armature, face, index, bone_indices):
	vertex = mesh.vertices[face.vertices[index]]
	v = mesh.vertices[face.vertices[index]]
	w = compute_weights(v, bone_indices, o.vertex_groups, len(o.vertex_groups))
	f.write(struct.pack("f", w[0][0]));
	f.write(struct.pack("f", w[1][0]));
	f.write(struct.pack("f", w[2][0]));
	f.write(struct.pack("f", w[3][0]));
	f.write(struct.pack("I", w[0][2]));
	f.write(struct.pack("I", w[1][2]));
	f.write(struct.pack("I", w[2][2]));
	f.write(struct.pack("I", w[3][2]));
	f.write(struct.pack("f", v.co.x))
	f.write(struct.pack("f", v.co.y))
	f.write(struct.pack("f", v.co.z))
	f.write(struct.pack("f", vertex.normal.x))
	f.write(struct.pack("f", vertex.normal.z))
	f.write(struct.pack("f", vertex.normal.y))
	uv = mesh.tessface_uv_textures[0].data[face.index].uv[index][0]
	f.write(struct.pack("f", uv))
	uv = mesh.tessface_uv_textures[0].data[face.index].uv[index][1]
	f.write(struct.pack("f", uv))
	return True

def write_indices(f, o, mesh, face, index):
	f.write(struct.pack("I", face.vertices[index]))
	
def write_str(f, str):
	l = len(str)
	f.write(struct.pack("I", l))
	f.write(bytes(str, "ascii"))
	return

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
			f.write(struct.pack("f", v.co.z))
			f.write(struct.pack("f", v.co.y))
	elif o["physics"] == "trimesh":
		m = o.to_mesh(context.scene, False, 'PREVIEW')
		f.write(struct.pack("I", len(m.vertices)));
		for v in m.vertices:
			f.write(struct.pack("f", v.co.x))
			f.write(struct.pack("f", v.co.z))
			f.write(struct.pack("f", v.co.y))
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
		p = mtx.translation;
		f.write(struct.pack("f", round(p.x, 8)))
		f.write(struct.pack("f", round(p.y, 8)))
		f.write(struct.pack("f", round(p.z, 8)))
		q = mtx.to_quaternion()
		f.write(struct.pack("f", round(q.x, 8)))
		f.write(struct.pack("f", round(q.y, 8)))
		f.write(struct.pack("f", round(q.z, 8)))
		f.write(struct.pack("f", round(q.w, 8)))
				
				
def write_skinned_model_indexed(context, f, armature, objs_to_export):
	meshes = []
	face_counts = []
	face_count = 0
	f.write(struct.pack("I", 7))
	f.write(bytes("f4i4pnt", "ascii"))
	bone_indices = {}
	bone_index = 0
	for b in armature.data.bones:
		bone_indices[b.name] = bone_index;
		bone_index = bone_index + 1
	indices = []
	vertices = []
	uvs = []
	index_base = 0
	max_idx = 0;
	for o in objs_to_export:
		m = o.to_mesh(context.scene, False, 'PREVIEW')
		m.transform(o.matrix_world)
		meshes.append(m)
		tri_list = extract_triangles(m)
		if m.tessface_uv_textures:
			vert_array, uv_array, tri_list = remove_face_uv_skinned(m.vertices, tri_list, bone_indices, o)
		else:
			print("error");
			
		for tri in tri_list:
			indices += [tri.vertex_index[0] + index_base, tri.vertex_index[2] + index_base, tri.vertex_index[1] + index_base]
		face_count += len(tri_list)
		face_counts.append(face_count)
		vertices += vert_array.values
		uvs += uv_array.values
		index_base = len(vertices)	
	
	f.write(struct.pack("I", len(indices)))
	for i in indices:
		f.write(struct.pack("I", i))
	f.write(struct.pack("I", len(vertices)))
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
		f.write(struct.pack("f", v.z))
		f.write(struct.pack("f", v.y))
		f.write(struct.pack("f", v.nx))
		f.write(struct.pack("f", v.nz))
		f.write(struct.pack("f", v.ny))
		f.write(struct.pack("f", uv.uv[0]))
		f.write(struct.pack("f", uv.uv[1]))

	write_skeleton(f, armature)

	index = 0
	f.write(struct.pack("I", len(meshes)))   
	for m in meshes:
		if m == None:
			material = ""
			f.write(struct.pack("I", len(material)))
			f.write(bytes(material, "ascii"))
		else:
			material = m.materials[0].name
			f.write(struct.pack("I", len(material)))
			f.write(bytes(material, "ascii"))
			
		if index == 0:
			f.write(struct.pack("I", face_counts[index]))
		else:
			f.write(struct.pack("I", face_counts[index] - face_counts[index - 1]))
		f.write(struct.pack("I", len(objs_to_export[index].name)))
		f.write(bytes(objs_to_export[index].name, "ascii"))
		index = index + 1
	return meshes
				
				
def write_skinned_model(context, f, armature, objs):
	f.write(struct.pack("I", 7))
	f.write(bytes("f4i4pnt", "ascii"))
	bone_indices = {}
	bone_index = 0
	for b in armature.data.bones:
		bone_indices[b.name] = bone_index;
		bone_index = bone_index + 1
	face_count = 0
	meshes = []
	face_counts = []
	for o in objs:
		m = o.to_mesh(context.scene, False, 'PREVIEW')
		m.transform(o.matrix_world)
		meshes.append(m)
		for face in m.tessfaces:
			if len(face.vertices) == 3:
				face_count += 1;
			if len(face.vertices) == 4:
				face_count += 2;
		face_counts.append(face_count)
	f.write(struct.pack("I", face_count))
	obj_idx = 0;
	for m in meshes:
		o = objs[obj_idx]
		obj_idx = obj_idx + 1
		for face in m.tessfaces:
			if len(face.vertices) == 3:
				write_vertex_skinned(f, o, m, armature, face, 0, bone_indices);
				write_vertex_skinned(f, o, m, armature, face, 1, bone_indices);
				write_vertex_skinned(f, o, m, armature, face, 2, bone_indices);
			if len(face.vertices) == 4:
				write_vertex_skinned(f, o, m, armature, face, 0, bone_indices);
				write_vertex_skinned(f, o, m, armature, face, 1, bone_indices);
				write_vertex_skinned(f, o, m, armature, face, 2, bone_indices);
				write_vertex_skinned(f, o, m, armature, face, 0, bone_indices);
				write_vertex_skinned(f, o, m, armature, face, 2, bone_indices);
				write_vertex_skinned(f, o, m, armature, face, 3, bone_indices);

	write_skeleton(f, armature)
	
	index = 0
	f.write(struct.pack("I", len(meshes)))   
	for m in meshes:
		if m == None:
			material = ""
			f.write(struct.pack("I", len(material)))
			f.write(bytes(material, "ascii"))
		else:
			material = m.materials[0].name
			f.write(struct.pack("I", len(material)))
			f.write(bytes(material, "ascii"))
		if index == 0:
			f.write(struct.pack("I", face_counts[index]))
		else:
			f.write(struct.pack("I", face_counts[index] - face_counts[index - 1]))
		f.write(struct.pack("I", len(objs[index].name)))
		f.write(bytes(objs[index].name, "ascii"))
		index = index + 1
	return meshes

def write_rigid_model_indexed(context, f, objs_to_export):
	meshes = []
	face_counts = []
	face_count = 0
	f.write(struct.pack("I", 3))
	f.write(bytes("pnt", "ascii"))
	indices = []
	vertices = []
	uvs = []
	index_base = 0
	max_idx = 0;
	for o in objs_to_export:
		m = o.to_mesh(context.scene, False, 'PREVIEW')
		m.transform(o.matrix_world)
		meshes.append(m)
		tri_list = extract_triangles(m)
		if m.tessface_uv_textures:
			vert_array, uv_array, tri_list = remove_face_uv(m.vertices, tri_list)
		else:
			print("error");
			
		for tri in tri_list:
			indices += [tri.vertex_index[0] + index_base, tri.vertex_index[2] + index_base, tri.vertex_index[1] + index_base]
		face_count += len(tri_list)
		face_counts.append(face_count)
		vertices += vert_array.values
		uvs += uv_array.values
		index_base = len(vertices)	
	
	f.write(struct.pack("I", len(indices)))
	for i in indices:
		f.write(struct.pack("I", i))
	f.write(struct.pack("I", len(vertices)))
	for v, uv in zip(vertices, uvs):
		f.write(struct.pack("f", v.x))
		f.write(struct.pack("f", v.z))
		f.write(struct.pack("f", v.y))
		f.write(struct.pack("f", v.nx))
		f.write(struct.pack("f", v.nz))
		f.write(struct.pack("f", v.ny))
		f.write(struct.pack("f", uv.uv[0]))
		f.write(struct.pack("f", uv.uv[1]))

	bone_count = 0
	f.write(struct.pack("I", bone_count))  

	index = 0
	f.write(struct.pack("I", len(meshes)))   
	for m in meshes:
		if m == None:
			material = ""
			f.write(struct.pack("I", len(material)))
			f.write(bytes(material, "ascii"))
		else:
			material = m.materials[0].name
			f.write(struct.pack("I", len(material)))
			f.write(bytes(material, "ascii"))
			
		if index == 0:
			f.write(struct.pack("I", face_counts[index]))
		else:
			f.write(struct.pack("I", face_counts[index] - face_counts[index - 1]))
		f.write(struct.pack("I", len(objs_to_export[index].name)))
		f.write(bytes(objs_to_export[index].name, "ascii"))
		index = index + 1
	return meshes
		
def write_rigid_model(context, f, objs_to_export):
	meshes = []
	face_counts = []
	face_count = 0
	f.write(struct.pack("I", 3))
	f.write(bytes("pnt", "ascii"))
	for o in objs_to_export:
		m = o.to_mesh(context.scene, False, 'PREVIEW')
		meshes.append(m)
		m.transform(o.matrix_world)
		for face in m.tessfaces:
			if len(face.vertices) == 3:
				face_count += 1;
			if len(face.vertices) == 4:
				face_count += 2;
		face_counts.append(face_count)

	f.write(struct.pack("I", face_count))
	for m in meshes:
		for face in m.tessfaces:
			if len(face.vertices) == 3:
				print("e3");
				write_vertex(f, o, m, face, 0);	
				write_vertex(f, o, m, face, 2);
				write_vertex(f, o, m, face, 1);
			if len(face.vertices) == 4:
				print("e4");
				write_vertex(f, o, m, face, 0);
				write_vertex(f, o, m, face, 2);
				write_vertex(f, o, m, face, 1);
				write_vertex(f, o, m, face, 0);
				write_vertex(f, o, m, face, 3);
				write_vertex(f, o, m, face, 2);

	bone_count = 0
	f.write(struct.pack("I", bone_count))  
	
	index = 0
	f.write(struct.pack("I", len(meshes)))   
	for m in meshes:
		if m == None:
			material = ""
			f.write(struct.pack("I", len(material)))
			f.write(bytes(material, "ascii"))
		else:
			material = m.materials[0].name
			f.write(struct.pack("I", len(material)))
			f.write(bytes(material, "ascii"))
			
		if index == 0:
			f.write(struct.pack("I", face_counts[index]))
		else:
			f.write(struct.pack("I", face_counts[index] - face_counts[index - 1]))
		f.write(struct.pack("I", len(objs_to_export[index].name)))
		f.write(bytes(objs_to_export[index].name, "ascii"))
		index = index + 1
	return meshes

def export_material(base_path, material, shader):
	path = base_path + "/" + material + ".mat"
	print("Exporting material " + path)	
	f_mat = open(path, "w")
	f_mat.write("\"texture\" : \"textures/" + material + ".dds\", \"shader\" : \"shaders/" + shader + ".shd\"");
	f_mat.close();
		
def add_meshes(objs, o):
	for i in o.children:
		if i.type == 'MESH':
			objs.append(i)
		
def write_some_data(context, filepath, export_materials):
	print(filepath)
	f = open(filepath, 'wb')
	object_count = len(context.selected_objects);
	armature = context.selected_objects[0].find_armature()
	objs = []
	for o in context.selected_objects:
		if o.type == 'MESH':
			objs.append(o)
		else:
			add_meshes(objs, o)
	
	shader = "rigid"
	if armature != None:
		shader = "skinned"
		meshes = write_skinned_model_indexed(context, f, armature, objs)
	else:
		meshes = write_rigid_model_indexed(context, f, objs)
	
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


class ExportSomeData(Operator, ExportHelper):
    """This appears in the tooltip of the operator and in the generated docs"""
    bl_idname = "export_test.some_data"  # important since its how bpy.ops.import_test.some_data is constructed
    bl_label = "Export Some Data"

    # ExportHelper mixin class uses this
    filename_ext = ".msh"

    filter_glob = StringProperty(
            default="*.txt",
            options={'HIDDEN'},
            )

    # List of operator properties, the attributes will be assigned
    # to the class instance from the operator settings before calling.
    export_materials = BoolProperty(
            name="Export Materials",
            description="Export Materials",
            default=False,
            )

    type = EnumProperty(
            name="Example Enum",
            description="Choose between two items",
            items=(('OPT_A', "First Option", "Description one"),
                   ('OPT_B', "Second Option", "Description two")),
            default='OPT_A',
            )

    def execute(self, context):
        return write_some_data(context, self.filepath, self.export_materials)


# Only needed if you want to add into a dynamic menu
def menu_func_export(self, context):
    self.layout.operator(ExportSomeData.bl_idname, text="Lux Mesh exporter")


def register():
    bpy.utils.register_class(ExportSomeData)
    bpy.types.INFO_MT_file_export.append(menu_func_export)


def unregister():
    bpy.utils.unregister_class(ExportSomeData)
    bpy.types.INFO_MT_file_export.remove(menu_func_export)

bl_info = {
    "name": "Lux Mesh exporter",
    "description": "Export mesh file in the Lux engine file format",
    "author": "Mikulas Florek",
    "version": (1, 0),
    "blender": (2, 68, 0),
    "location": "File > Export",
    "warning": "", # used for warning icon and text in addons panel
    "wiki_url": "http://wiki.blender.org/index.php/Extensions:2.5/Py/"
                "Scripts/My_Script",
    "category": "Import-Export"}
	

if __name__ == "__main__":
    register()
