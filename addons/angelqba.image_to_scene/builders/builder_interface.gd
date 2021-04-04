tool
extends Node

# Name of the builder. Can be specified in layer name. TYPE:PROCESSOR:BUILDER -> terrain:MyProcessor:MyBuilder
var builder_name
# Type of layer. Can be specified in layer name. TYPE:PROCESSOR:BUILDER -> terrain:MyProcessor:MyBuilder
var builder_type

# generate a MeshInstance from processed data
# data: 
#{
#	'name': layer name
#	'width': image width
#	'height': image height
#	'point_groups': array of grids of Vector3 points. Full transparent pixels in image are translated to null valuen
#}
func build(data):
	var arr = []
		
	arr.resize(Mesh.ARRAY_MAX)
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()
	
	if true:
		var width = data['width']
		var height = data['height']

		for point_group in data['point_groups']:
			for z in range(0, height):
				for x in range(0, width):
					# verify that is not null
					if point_group[x][z]:
						verts.push_back(point_group[x][z]['vector'])
						uvs.push_back(Vector2(x / width, z / height))
						
						if z < height - 1 and x < width - 1:
							var current_point = point_group[x][z]
							var plus_x = point_group[x + 1][z]
							var plus_z = point_group[x][z + 1]
							var plus_xz = point_group[x + 1][z + 1]
							
							if plus_x and plus_xz and plus_z:
								#variante 1
								if plus_x and plus_xz:
									indices.append(current_point['index'])
									indices.append(plus_x['index'])
									indices.append(plus_xz['index'])
									
								if plus_z and plus_xz:
									indices.append(current_point['index'])
									indices.append(plus_xz['index'])
									indices.append(plus_z['index'])
							else:
								if not plus_x and not plus_z and not plus_xz:
									pass
								else:
									var other_points_count = 0
									if plus_x:
										other_points_count += 1
									
									if plus_z:
										other_points_count += 1
										
									if plus_xz:
										other_points_count += 1
										
									# si hay solo otro punto no puedo hacer un triangulo
									if other_points_count == 2:
										if not plus_x:
											indices.append(current_point['index'])
											indices.append(plus_xz['index'])
											indices.append(plus_z['index'])
											
										if not plus_z:
											indices.append(current_point['index'])
											indices.append(plus_x['index'])
											indices.append(plus_xz['index'])
											
										if not plus_xz:
											indices.append(current_point['index'])
											indices.append(plus_x['index'])
											indices.append(plus_z['index'])
					else:
						if z < height - 1 and x < width - 1:
							var plus_x = point_group[x + 1][z]
							var plus_z = point_group[x][z + 1]
							var plus_xz = point_group[x + 1][z + 1]
							
							if plus_x and plus_xz and plus_z:
								if plus_x and plus_z and plus_xz:
									indices.append(plus_x['index'])
									indices.append(plus_xz['index'])
									indices.append(plus_z['index'])
	
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
#	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices
	
	var mesh_instance = MeshInstance.new()
	var mesh: Mesh = Mesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	
	var surfaceTool = SurfaceTool.new()
#	surfaceTool.add_smooth_group(true)  # this don't work
	surfaceTool.append_from(mesh, 0, Transform.IDENTITY)
	surfaceTool.generate_normals()
	mesh = surfaceTool.commit()
	
	var mat = SpatialMaterial.new()
	if data['name'].begins_with('terrain'):
		mat.albedo_color = Color(.5, .25, 0)
		
	if data['name'].begins_with('water'):
		mat.albedo_color = Color(.5, .5, 1, .5)
		mat.flags_transparent = true
	
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	
	return mesh_instance
