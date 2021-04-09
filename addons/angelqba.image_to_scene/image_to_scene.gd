tool
extends Spatial

# route to a TIFF image
export(String, FILE, "*.tiff") var image_path setget set_image_path
# custom resource to store tiff parsed information
export(Resource) var image_data_resource = ImageDataReource.new()
# scale applied to height values
export(float) var heigth_scale = 0.1
# scale applied to the resulting model
export(float) var total_scale = 0.1

signal image_changed

# sets image path and emit a signal to upddate the image preview
func set_image_path(value):
	image_path = value
	emit_signal("image_changed")
