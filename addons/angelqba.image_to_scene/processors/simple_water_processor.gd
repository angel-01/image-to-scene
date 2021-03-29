extends "res://addons/angelqba.image_to_scene/processors/processor_interface.gd"

var processor_name = 'SimpleWaterProcessor'
var processor_type = 'water'
var previous_layer
var heigth_scale
var total_scale
var mult

func process(layers, current_layer, current_result, selected_node):
	heigth_scale = selected_node.heigth_scale
	total_scale = selected_node.total_scale
	mult = heigth_scale * total_scale
	previous_layer = current_result['layers'].back()
	
	var result = .process(layers, current_layer, current_result, selected_node)
	
	for z in range(0, height):
		for x in range(0, width):
			var no_previous_point = false
			for pg in previous_layer['point_groups']:
				for result_pg in result['point_groups']:
					if pg[x][z] and result_pg[x][z]:
						var tmp = pg[x][z]['vector'].y
						pg[x][z]['vector'].y -= result_pg[x][z]['vector'].y
						result_pg[x][z]['vector'].y = tmp
					else:
						no_previous_point = true

			if no_previous_point:
				continue
	
	return result

func get_y(r, g, b):
	return 255 * 3 * mult - (r + g + b) * mult
