extends "res://addons/angelqba.image_to_scene/builders/builder_interface.gd"

func _init().():
	builder_name = 'SimpleObjectBuilder'
	builder_type = 'object'

func build(data):
	
	print(len(data['point_groups']))
	
	return MeshInstance.new()
