tool
extends Spatial

export(String, FILE, "*.tiff") var image_path setget set_image_path
export(Resource) var image_data_resource = ImageDataReource.new()
export(float) var heigth_scale = 0.5
export(float) var total_scale = 0.1

var image_data = []

signal image_changed

func set_image_path(value):
	image_path = value
	emit_signal("image_changed")
