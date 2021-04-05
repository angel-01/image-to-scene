tool
extends ScrollContainer

var fields = []
var field_types = {
	'file': preload("res://addons/angelqba.image_to_scene/views/inspector_fields/TextField.tscn")
}

func add_field(field_configuration, value=null):
	print(field_configuration)
	var grid = find_node('GridContainer')
	if field_configuration['type'] in field_types:
		var new_field = field_types[field_configuration['type']].instance()
		grid.add_child(new_field)

func clear():
	pass
