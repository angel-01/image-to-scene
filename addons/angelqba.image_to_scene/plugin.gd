tool
extends EditorPlugin

# TODO:
# -refactor: rendeadores plugueables
# -permitir especificar el procesador/rendeador en el nombre del layout.
#	algo como: terrain:SimpleTerrainProcesor:SimpleTerrainRender

# SUBIR A GIT:
#	-COMENTAR
#	-DOCUMENTAR
#	-SUBIR A GIT
#	-PUBLICAR
#		-TWITTER
#		-REDDIT
#		-ITCH.IO

# -adicionar zonas de objetos. integrar con addon "scatter"
# TODO: permitir varias "islas" independientes???
# optimizar? si una capa no fue modificada en la imagen, no volver a generarla?


var tiff_loader = preload("res://addons/angelqba.image_to_scene/tools/tiff_loader.gd").new()

# A class member to hold the dock during the plugin life cycle.
var dock
var _options_view = preload("res://addons/angelqba.image_to_scene/views/_options_view.tscn").instance()
var _editor_selection
var selected_node: Spatial
var _image_to_scene_type = preload("res://addons/angelqba.image_to_scene/image_to_scene.gd")
var ProcessorManager = null

func _enter_tree():
	# Initialization of the plugin goes here.
	# Add the new type with a name, a parent type, a script and an icon.
	add_custom_type("ImageToScene", "Spatial", preload("image_to_scene.gd"), preload("icon.png"))
	
	var base_control = get_editor_interface().get_base_control()
	_options_view.base_control = base_control
#	_options_view.call_deferred("setup_dialogs", base_control)
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

	# Register processor manager singleton
#	add_autoload_singleton('ProcessorManager', "res://addons/angelqba.image_to_scene/processor_manager.gd")
	var processor_manager = preload("res://addons/angelqba.image_to_scene/processor_manager.gd").new()
	
	processor_manager.connect('ready', self, 'register_processors')
	
#	get_tree().root.add_child(processor_manager)
	get_tree().root.call_deferred('add_child', processor_manager)
	
func _exit_tree():
	# Clean-up of the plugin goes here.
	# Always remember to remove it from the engine when deactivated.
	remove_custom_type("ImageToScene")
	remove_autoload_singleton('ProcessorManager')
	
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
		
func preprocess():
	var start = OS.get_ticks_msec()
	var time_terrain = 0.0
	var time_water = 0.0
	var result = {
		'layers': []
	}
	for data in selected_node.image_data_resource.data:
		
#		var width = data['ImageWidth']
#		var height = data['ImageLength']
#		var samples_per_pixel = data['SamplesPerPixel']
		
		var layer
#		var layer = {
#			'name': data['PageName'],
#			'width': width,
#			'height': height,
#			'samples_per_pixel': samples_per_pixel,
#			'point_groups': []
#		}
		print('selected node ', selected_node)
		if data['PageName'].begins_with('terrain'):
				var s = OS.get_ticks_msec()
				# TODO: seleccinar dinamicamente
				var processor = ProcessorManager.processors['terrain']['SimpleTerrainProcessor']
				layer = processor.process(
					selected_node.image_data_resource.data, 
					data, 
					result, 
					selected_node
				)
				time_terrain = OS.get_ticks_msec() - s
				
		if data['PageName'].begins_with('water'):
				var s = OS.get_ticks_msec()
				var processor = ProcessorManager.processors['water']['SimpleWaterProcessor']
				layer = processor.process(
					selected_node.image_data_resource.data, 
					data, 
					result, 
					selected_node
				)
				time_water = OS.get_ticks_msec() - s
				
		result['layers'].append(layer)
		
	var total_time = OS.get_ticks_msec() - start
	print('preprocess time: ', total_time)
	print('time_terrain time: ', time_terrain)
	print('time_water time: ', time_water)
	print('terrain %: ', float(time_terrain) / total_time * 100.0)
	print('water %: ', float(time_water) / total_time * 100.0)
	
	return result
		
func update_model():
	
	for n in selected_node.get_children():
		selected_node.remove_child(n)
	
	var preprocessed_layers = preprocess()
#
	for data in preprocessed_layers['layers']:

		var arr = []
		
		arr.resize(Mesh.ARRAY_MAX)
		var verts = PoolVector3Array()
		var uvs = PoolVector2Array()
		var normals = PoolVector3Array()
		var indices = PoolIntArray()
#		if data['name'] == 'water':
#			continue
		if true:
			var width = data['width']
			var height = data['height']

			for point_group in data['point_groups']:
				for z in range(0, height):
					for x in range(0, width):
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
	#	surfaceTool.add_smooth_group(true)
		surfaceTool.append_from(mesh, 0, Transform.IDENTITY)
		surfaceTool.generate_normals()
	#	surfaceTool.generate_tangents()
		mesh = surfaceTool.commit()
		
		var mat = SpatialMaterial.new()
		if data['name'].begins_with('terrain'):
			mat.albedo_color = Color(.5, .25, 0)
			
		if data['name'].begins_with('water'):
			mat.albedo_color = Color(.5, .5, 1, .5)
			mat.flags_transparent = true
		
		mesh_instance.mesh = mesh
		mesh_instance.material_override = mat

		selected_node.add_child(mesh_instance)
		mesh_instance.owner = get_editor_interface().get_edited_scene_root()											
	
func register_processors():
	ProcessorManager = get_tree().root.get_node("ProcessorManager")
	
	# Register processors
	var processors = [
		preload("res://addons/angelqba.image_to_scene/processors/simple_terrain_processor.gd").new(),
		preload("res://addons/angelqba.image_to_scene/processors/simple_water_processor.gd").new()
	]
	
	for p in processors:
		ProcessorManager.processors[p.processor_type][p.processor_name] = p
