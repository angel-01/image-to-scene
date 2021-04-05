tool
extends EditorPlugin

var tiff_loader

# options panel. Shown when an ImageToScene node is selected
var _options_view: Node
# layer inspector. Shown when an ImageToScene node is selected, ana a layer is selected in options panel
var layer_inspector: Node
# editor's current selection
var _editor_selection
# stores current selected ImageToScene node
var selected_node: Spatial
# ImageToScene type. Used to compare the selected node in the editor
var _image_to_scene_type = preload("res://addons/angelqba.image_to_scene/image_to_scene.gd")
# Where processors are registered
var ProcessorManager = null
# Wehere renrers are registered
var BuilderManager = null

func _enter_tree():
	# Initialization of the plugin goes here.
	
	_options_view  = preload("res://addons/angelqba.image_to_scene/views/_options_view.tscn").instance()
	layer_inspector  = preload("res://addons/angelqba.image_to_scene/views/LayerInspector.tscn").instance()
	tiff_loader = preload("res://addons/angelqba.image_to_scene/tools/tiff_loader.gd").new()
	# Add the new type with a name, a parent type, a script and an icon.
	add_custom_type("ImageToScene", "Spatial", preload("image_to_scene.gd"), preload("icon.png"))
	
	var base_control = get_editor_interface().get_base_control()
#	_options_view.base_control = base_control
	_options_view.connect('update_image_preview', self, 'update_image_preview')
	_options_view.connect('update_model', self, 'update_model')
	_options_view.connect('layer_selected', self, 'layer_selected')

	_editor_selection = get_editor_interface().get_selection()
	_editor_selection.connect("selection_changed", self, "_on_selection_changed")
#	connect("scene_changed", self, "_on_scene_changed")

	ProcessorManager = preload("res://addons/angelqba.image_to_scene/processor_manager.gd").new()
	ProcessorManager.connect('ready', self, 'register_processors')
	BuilderManager = preload("res://addons/angelqba.image_to_scene/builder_manager.gd").new()
	BuilderManager.connect('ready', self, 'register_builders')
	
	get_tree().root.call_deferred('add_child', ProcessorManager)
	get_tree().root.call_deferred('add_child', BuilderManager)
	
func _exit_tree():
	# Clean-up of the plugin goes here.
	# Always remember to remove it from the engine when deactivated.
	remove_custom_type("ImageToScene")
	_options_view.queue_free()
	layer_inspector.queue_free()
	tiff_loader.queue_free()
	ProcessorManager.queue_free()
	BuilderManager.queue_free()

func _on_selection_changed() -> void:
	var selected = _editor_selection.get_selected_nodes()

	if selected.empty():
		# Node was deselected but nothing else was selected. By default, Godot
		# will keep the path editor panel on top so we do the same.
		return
		
	# if this is an ImageToScene node
	if selected[0] is _image_to_scene_type:
		selected_node = selected[0]
		selected_node.connect('image_changed', self, 'update_image_preview')
		update_image_preview()
		_show_options_panel()
		
	else:
		selected_node.disconnect('image_changed', self, 'update_image_preview')
		selected_node = null
		_hide_options_panel()

func _show_options_panel():
	if not _options_view.get_parent():
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _options_view)

func _hide_options_panel():
	if _options_view.get_parent():
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _options_view)
#		remove_control_from_container(EditorPlugin.CONTAINER_PROPERTY_EDITOR_BOTTOM, layer_inspector)
		remove_control_from_bottom_panel(layer_inspector)

# generate images for options panel
func update_image_preview():
	if selected_node and selected_node.image_path:
		# load data from tiff
		var data = tiff_loader.load_tiff(selected_node.image_path)
		var data_resource = ImageDataReource.new()
		data_resource.data = data
		# save tiff data in a resource 
		ResourceSaver.save(selected_node.image_data_resource.resource_path, data_resource)
		selected_node.image_data_resource = data_resource
		# generate image from tiff data
		var image: Image = tiff_loader.load_tiff_image_from_data(data)

		var t = ImageTexture.new()
		t.create_from_image(image, 0)
		# show image in options panel
		_options_view.find_node('ImagePreview').texture = t
		
		# generate preview from tiff layers
		var layers_view: ItemList = _options_view.find_node('ItemList')
		layers_view.clear()
		for i in data:
			var icon = tiff_loader.get_image_from_layer_data(i)
			var icon_texture = ImageTexture.new()
			icon_texture.create_from_image(icon, 0)
			layers_view.add_item(i.PageName, icon_texture)
		
# convert color data from tiff image to coords and height values
func preprocess():
	
	# performance measurements
	var start = OS.get_ticks_msec()
	var measurements = []
	var result = {
		'layers': []
	}
	for data in selected_node.image_data_resource.data:
		var measurement = {
			"start": OS.get_ticks_msec(),
			"end": '',
			"duration": '',
			"name": data['PageName']
		}
		
		# gets type of layer and Processor if exists
		var parts = parse_layer_name(data['PageName'])
		var type = parts['type']
		var processor_type = parts['processor_type']
				
		var processor = get_processor(type, processor_type)
		
		# -selected_node.image_data_resource.data: Information parsed from TIFF.
		#	It includes all layers
		# -data: current layer information (from TIFF image)
		# -result: current result. Used for modifying previous processed layers
		# -selected_node: Current selected ImageToScene node
		
		# RETURNS:
#		{
#			'name': Layer name
#			'width': Image width 
#			'height': Image Height
#			'samples_per_pixel': 3 if image is RGB, 4 if image is RGBA
#			'point_groups': list of grids with a {vector: Vector3, index: int} object points. Usually only one group is generated, but supports more for generating "islands" of points. Includes full transparent points as null values
#		}
		var layer = processor.process(
			selected_node.image_data_resource.data, 
			data, 
			result, 
			selected_node
		)
		
		result['layers'].append(layer)
		
		measurement['end'] = OS.get_ticks_msec()
		measurement["duration"] = measurement['end'] - measurement['start']
		
		measurements.append(measurement)
		
	var total_time = OS.get_ticks_msec() - start
	print()
	print('preprocess time: ', total_time)
	
	for i in measurements:
		print(i['name'], ", duration: ", i['duration'], ', percent: ', float(i['duration']) / total_time * 100.0)
	
	return result
		
func update_model():
	
	# remove children of selected ImageToScene node
	for n in selected_node.get_children():
		selected_node.remove_child(n)
	
	# preprocess data
	var preprocessed_layers = preprocess()
	
	# performance measurements
	var start = OS.get_ticks_msec()
	var measurements = []
	var result = {
		'layers': []
	}
	
	for data in preprocessed_layers['layers']:
		var measurement = {
			"start": OS.get_ticks_msec(),
			"end": '',
			"duration": '',
			"name": data['name']
		}
		
		var parts = parse_layer_name(data['PageName'])
		var type = parts['type']
		var builder_type = parts['builder_type']
		
		var builder = get_builder(type, builder_type)
		
		var mesh_instance = builder.build(data)

		selected_node.add_child(mesh_instance)
		mesh_instance.owner = get_editor_interface().get_edited_scene_root()
		
		measurement['end'] = OS.get_ticks_msec()
		measurement["duration"] = measurement['end'] - measurement['start']
		
		measurements.append(measurement)
		
	var total_time = OS.get_ticks_msec() - start
	print()
	print('builder time: ', total_time)
	
	if total_time:
		for i in measurements:
			print(i['name'], ", duration: ", i['duration'], ', percent: ', float(i['duration']) / total_time * 100.0)
	
# add processors to the "global" processor registry
func register_processors():
	ProcessorManager = get_tree().root.get_node("ProcessorManager")
	
	# Register processors
	var processors = [
		preload("res://addons/angelqba.image_to_scene/processors/simple_terrain_processor.gd").new(),
		preload("res://addons/angelqba.image_to_scene/processors/simple_water_processor.gd").new()
	]
	
	for p in processors:
		ProcessorManager.processors[p.processor_type][p.processor_name] = p

# add builder to the "global" builder registry	
func register_builders():
	BuilderManager = get_tree().root.get_node("BuilderManager")
	
	# Register processors
	var builders = [
		preload("res://addons/angelqba.image_to_scene/builders/simple_terrain_builder.gd").new(),
		preload("res://addons/angelqba.image_to_scene/builders/simple_water_builder.gd").new()
	]
	
	for r in builders:
		BuilderManager.builders[r.builder_type][r.builder_name] = r

func layer_selected(index):
	print('index: ', index)
	print(selected_node.image_data_resource.data[index]['PageName'])
	if index == -1:
#		remove_control_from_container(EditorPlugin.CONTAINER_PROPERTY_EDITOR_BOTTOM, layer_inspector)
		remove_control_from_bottom_panel(layer_inspector)
	else:
		if not layer_inspector.get_parent():
			add_control_to_bottom_panel(layer_inspector, 'Layer Inspector')
			
	if layer_inspector.get_parent():
		var parts = parse_layer_name(selected_node.image_data_resource.data[index]['PageName'])
		var type = parts['type']
		var builder_type = parts['builder_type']
		
		print('parts: ', parts)
		
		var builder = get_builder(type, builder_type)
		
		print('builder: ', builder)
		print('layer_inspector: ', layer_inspector)
		
		if builder:
			print('configuration_fields: ', builder.configuration_fields)
			for configuration_field in builder.configuration_fields:
				layer_inspector.add_field(configuration_field)
					
#		add_control_to_container(EditorPlugin.CONTAINER_PROPERTY_EDITOR_BOTTOM, layer_inspector)

func parse_layer_name(layer_name):
	# gets type of layer and Processor if exists
	var parts = layer_name.split(':')
	var re = RegEx.new()
	re.compile(' +')
	
	# type is the first block without spaces. 
	#	ex: terrain:MyTerrainProcessor -> terrain
	#	my terrain:MyTerrainProcessor -> my
	var type = re.sub(parts[0], '', true)
	
	var processor_type = null
	
	if len(parts) > 1:
		if parts[1]:
			processor_type = parts[1]
	
	var builder_type = null
	
	if len(parts) > 2:
		if parts[2]:
			builder_type = parts[2]
			
	return {
		'type': type,
		'processor_type': processor_type,
		'builder_type': builder_type,
	}

func get_builder(type, builder_type):
	if not builder_type:
		if not type in BuilderManager.builders:
			print("No builder registered for type %s" % type)
			return null
			
		# gets the first builder of layer type
		for r in BuilderManager.builders[type]:
			builder_type = r
			break
			
	return BuilderManager.builders[type][builder_type]
	
func get_processor(type, processor_type):
	if not processor_type:
		if not type in ProcessorManager.processors:
			print("No processor registered for type %s" % type)
			return null
		
		# gets the first processor of layer type
		for p in ProcessorManager.processors[type]:
			processor_type = p
			break
			
	return ProcessorManager.processors[type][processor_type]
