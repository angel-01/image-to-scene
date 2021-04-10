extends "res://addons/angelqba.image_to_scene/builders/builder_interface.gd"

func _init().():
	builder_name = 'SimpleWaterBuilder'
	builder_type = 'water'
	
	configuration_fields.append({
		'name': "material-SimpleWaterBuilder",
		'title': "Material",
		'type': 'file',
		'masks': ["*.tres ; Material files"]
	})


func build(data, selected_node):
	var mesh_instance = .build(data, selected_node)
	
	if "material-SimpleWaterBuilder" in selected_node.image_data_resource.configuration_values:
		var material_path = selected_node.image_data_resource.configuration_values["material-SimpleWaterBuilder"]
		if material_path:
			var mat = load(material_path)
			mesh_instance.material_override = mat
			
	return mesh_instance
