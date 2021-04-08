tool
extends ScrollContainer

var fields = []
var selected_node
var field_types = {
	'file': preload("res://addons/angelqba.image_to_scene/views/inspector_fields/FileField.tscn"),
	'int': preload("res://addons/angelqba.image_to_scene/views/inspector_fields/IntegerField.tscn"),
	'float': preload("res://addons/angelqba.image_to_scene/views/inspector_fields/FloatField.tscn"),
}

func add_field(field_configuration, value=null):
	print(field_configuration)
	var grid = find_node('GridContainer')
	if field_configuration['type'] in field_types:
		var new_field: Node = field_types[field_configuration['type']].instance()
		new_field.set_title(field_configuration['title'])
		if field_configuration['name'] in selected_node.image_data_resource.configuration_values:
			new_field.set_value(selected_node.image_data_resource.configuration_values[field_configuration['name']])
		
		new_field.connect('on_value_changed', self, "on_value_changed", [field_configuration])
		grid.add_child(new_field)

func clear():
	var grid: GridContainer = find_node('GridContainer')
	for i in grid.get_children():
		i.queue_free()

func on_value_changed(value, field_configuration):
	print('cambio el valooooooooor')
	print('value: ', value)
	print('field_configuration: ', field_configuration)
	selected_node.image_data_resource.configuration_values[field_configuration['name']] = value
	print('image_data_resource: ', selected_node.image_data_resource)
	print('resource_path: ', selected_node.image_data_resource.resource_path)
	print(ResourceSaver.save(selected_node.image_data_resource.resource_path, selected_node.image_data_resource))
	
