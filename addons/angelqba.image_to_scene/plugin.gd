tool
extends EditorPlugin

var tiff_loader = preload("res://addons/angelqba.image_to_scene/tools/tiff_loader.gd").new()

# A class member to hold the dock during the plugin life cycle.
var dock
var _options_view = preload("res://addons/angelqba.image_to_scene/views/_options_view.tscn").instance()
var _editor_selection
var selected_node: Spatial
var _image_to_scene_type = preload("res://addons/angelqba.image_to_scene/image_to_scene.gd")

func _enter_tree():
	# Initialization of the plugin goes here.
	# Add the new type with a name, a parent type, a script and an icon.
	add_custom_type("ImageToScene", "Spatial", preload("image_to_scene.gd"), preload("icon.png"))
	
	var base_control = get_editor_interface().get_base_control()
	_options_view.base_control = base_control
	_options_view.call_deferred("setup_dialogs", base_control)
	_options_view.connect('update_image_preview', self, 'update_image_preview')
	_options_view.connect('update_model', self, 'update_model')
	# Load the dock scene and instance it.
#	dock = preload("res://addons/angelqba.fsm/dock.tscn").instance()

	# Add the loaded scene to the docks.
#	add_control_to_bottom_panel(dock, 'FSM')
	# Note that LEFT_UL means the left of the editor, upper-left dock.
	_editor_selection = get_editor_interface().get_selection()
	_editor_selection.connect("selection_changed", self, "_on_selection_changed")
#	connect("scene_changed", self, "_on_scene_changed")


func _exit_tree():
	# Clean-up of the plugin goes here.
	# Always remember to remove it from the engine when deactivated.
	remove_custom_type("ImageToScene")
	
	
	# Clean-up of the plugin goes here.
	# Remove the dock.
#	remove_control_from_bottom_panel(dock)
	# Erase the control from the memory.
#	dock.free()

func _on_selection_changed() -> void:
	var selected = _editor_selection.get_selected_nodes()

	if selected.empty():
		# Node was deselected but nothing else was selected. By default, Godot
		# will keep the path editor panel on top so we do the same.
		return
		
	if selected[0] is _image_to_scene_type:
		selected_node = selected[0]
		selected_node.connect('image_changed', self, 'update_image_preview')
		update_image_preview()
		_show_options_panel()
#		_scatter_path_gizmo_plugin.set_selection(selected[0])
#		selected[0].undo_redo = get_undo_redo()
#
#		if _gizmo_options.snap_to_colliders():
#			_on_snap_to_colliders_enabled()
	else:
		selected_node.disconnect('image_changed', self, 'update_image_preview')
		selected_node = null
		_hide_options_panel()
#		_scatter_path_gizmo_plugin.set_selection(null)

func _show_options_panel():
	if not _options_view.get_parent():
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _options_view)

func _hide_options_panel():
	if _options_view.get_parent():
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _options_view)

func update_image_preview():
	if selected_node and selected_node.image_path:
		var data = tiff_loader.load_tiff(selected_node.image_path)
#		selected_node.image_data_resource.data = data
		var data_resource = ImageDataReource.new()
		data_resource.data = data
		ResourceSaver.save(selected_node.image_data_resource.resource_path, data_resource)
		selected_node.image_data_resource = data_resource
		var image: Image = tiff_loader.load_tiff_image_from_data(data)

		var t = ImageTexture.new()
		t.create_from_image(image, 0)
		_options_view.find_node('ImagePreview').texture = t
		
		var layers_view: ItemList = _options_view.find_node('ItemList')
		layers_view.clear()
		for i in data:
			print(i)
			var icon = tiff_loader.get_image_from_layer_data(i)
			var icon_texture = ImageTexture.new()
			icon_texture.create_from_image(icon, 0)
			layers_view.add_item(i.PageName, icon_texture)
		
func update_model():
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()
	
	
#	verts.append(Vector3(0, 0, 0))
#	verts.append(Vector3(100, 0, 0))
#	verts.append(Vector3(0, 0, 100))
#	verts.append(Vector3(100, 0, 100))
#
#	indices.append(0)
#	indices.append(1)
#	indices.append(2)
#
#	indices.append(1)
#	indices.append(3)
#	indices.append(2)


#	var tmpMesh = Mesh.new()
#	var vertices = PoolVector3Array()
#	var UVs = PoolVector2Array()
#	var mat = SpatialMaterial.new()
#	var color = Color(0.9, 0.1, 0.1)
#
#	mat.albedo_color = color
#
#	var st = SurfaceTool.new()
#	st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
#	st.set_material(mat)
#
	for data in selected_node.image_data_resource.data:

		if data['PageName'] == 'terrain':
			var width = data['ImageWidth']
			var height = data['ImageLength']

			var index = 0
			for z in range(0, height):
				for x in range(0, width):
					var red = data['data'][index]
					var green = data['data'][index + 1]
					var blue = data['data'][index + 2]

					verts.push_back(
						Vector3(
							x * selected_node.total_scale - width / 2 * selected_node.total_scale, 
							(red + green) * selected_node.heigth_scale * selected_node.total_scale, 
							z * selected_node.total_scale - height / 2 * selected_node.total_scale
						)
					)
					var normal = Vector3.UP
#					
					uvs.push_back(Vector2(x / width, z / height))
					
					if z < height - 1:
						if x < width - 1:
							indices.append(x + z * width)
							indices.append(x + z * width + 1)
							indices.append(x + (z + 1) * width)
							
						if x > 0:
							indices.append(x + z * width)
							indices.append(x + (z + 1) * width)
							indices.append(x + (z + 1) * width - 1)

					normals.push_back(normal)
					index += data['SamplesPerPixel']
						
#
#	for v in vertices.size(): 
#		st.add_color(color)
##		st.add_uv(UVs[v])
#		st.add_uv(Vector2(vertices[v].x, vertices[v].z))
#		st.add_vertex(vertices[v])
#
#	st.commit(tmpMesh)
#
	for n in selected_node.get_children():
		selected_node.remove_child(n)
#
#	var mesh_instance = MeshInstance.new()
#	mesh_instance.mesh = tmpMesh

	
	
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
#	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices
	
	var mesh_instance = MeshInstance.new()
	var mesh: Mesh = Mesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	
	# Calculate vertex normals, face-by-face.
	for i in range(mdt.get_face_count()):
		# Get the index in the vertex array.
		var a = mdt.get_face_vertex(i, 0)
		var b = mdt.get_face_vertex(i, 1)
		var c = mdt.get_face_vertex(i, 2)
		# Get vertex position using vertex index.
		var ap = mdt.get_vertex(a)
		var bp = mdt.get_vertex(b)
		var cp = mdt.get_vertex(c)
		# Calculate face normal.
		var n = (bp - cp).cross(ap - bp).normalized()
		# Add face normal to current vertex normal.
		# This will not result in perfect normals, but it will be close.
		mdt.set_vertex_normal(a, n + mdt.get_vertex_normal(a))
		mdt.set_vertex_normal(b, n + mdt.get_vertex_normal(b))
		mdt.set_vertex_normal(c, n + mdt.get_vertex_normal(c))
		
	# Run through vertices one last time to normalize normals and
	# set color to normal.
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex_normal(i).normalized()
		mdt.set_vertex_normal(i, v)
		mdt.set_vertex_color(i, Color(v.x, v.y, v.z))

	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	
	mesh_instance.mesh = mesh

	selected_node.add_child(mesh_instance)
	mesh_instance.owner = get_editor_interface().get_edited_scene_root()
