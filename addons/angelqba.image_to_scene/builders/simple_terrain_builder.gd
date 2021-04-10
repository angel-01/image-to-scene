extends "res://addons/angelqba.image_to_scene/builders/builder_interface.gd"

func _init().():
	builder_name = 'SimpleTerrainBuilder'
	builder_type = 'terrain'
	
	configuration_fields.append({
		'name': "material-SimpleTerrainBuilder",
		'title': "Material",
		'type': 'file',
		'masks': ["*.tres ; Material files"]
	})


func build(data, selected_node):
	var mesh_instance = .build(data, selected_node)
	
	if "material-SimpleTerrainBuilder" in selected_node.image_data_resource.configuration_values:
		var material_path = selected_node.image_data_resource.configuration_values["material-SimpleTerrainBuilder"]
		if material_path:
			var mat = load(material_path)
			mesh_instance.material_override = mat
			
	return mesh_instance
