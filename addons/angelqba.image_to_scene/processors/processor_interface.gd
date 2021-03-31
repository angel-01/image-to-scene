tool
extends Node

var processor_name
var processor_type
var width
var height
var samples_per_pixel
var point_group = []
var layer
var selected_node

# -layers: Information parsed from TIFF.
#	It includes all layers
# -current_layer: current layer information (from TIFF image)
# -current_result: current result. Used for modifying previous processed layers
# -selected_node: Current selected ImageToScene node

# RETURNS:
#		{
#			'name': Layer name
#			'width': Image width 
#			'height': Image Height
#			'samples_per_pixel': 3 if image is RGB, 4 if image is RGBA
#			'point_groups': list of grids with a {vector: Vector3, index: int} object points. Usually only one group is generated, but supports more for generating "islands" of points. Includes full transparent points as null values
#		}
func process(layers, current_layer, current_result, selected_node):
	self.selected_node = selected_node
	width = current_layer['ImageWidth']
	height = current_layer['ImageLength']
	samples_per_pixel = current_layer['SamplesPerPixel']

	layer = {
		'name': current_layer['PageName'],
		'width': width,
		'height': height,
		'samples_per_pixel': samples_per_pixel,
		'point_groups': []
	}
	
	point_group = []
	for i in range(0, width):
		var arr = []
		arr.resize(height)
		point_group.append(arr)
		
#	current_layer['data'] is a 1d array with all the points. index will hold the current position
	var index = 0
	var not_null_index = 0
	for z in range(0, height):
		for x in range(0, width):
			var red = current_layer['data'][index]
			var green = current_layer['data'][index + 1]
			var blue = current_layer['data'][index + 2]
			
			var point_x = get_x(x, red, green, blue)
			var point_y = get_y(red, green, blue)
			var point_z = get_z(z, red, green, blue)
			
			if samples_per_pixel == 4:
				var alpha = current_layer['data'][index + 3]
				
				# if is full transparent, sets a null value at these coordinates 
				if not alpha:
					point_group[x][z] = null
					index += samples_per_pixel
					continue
				# else, y value is reduced by how much transparent it is
				else:
					var ratio = alpha / 255.0
					point_y *= ratio
					
			point_group[x][z] = {
				'vector': Vector3(
					point_x, 
					point_y, 
					point_z
				),
				'index': not_null_index # used latter in mesh contruction
			}
			
			not_null_index += 1
			index += samples_per_pixel
			
	layer['point_groups'].append(point_group)
	
	return layer

func get_x(x, r, g, b):
	# scale and center in x axis
	return x * selected_node.total_scale - width / 2 * selected_node.total_scale

func get_y(r, g, b):
	# scale and set y value by adding color's components
	return (r + g + b) * selected_node.heigth_scale * selected_node.total_scale 

func get_z(z, r, g, b):
	# scale and center in z axis
	return z * selected_node.total_scale - height / 2 * selected_node.total_scale
