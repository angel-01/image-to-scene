extends "res://addons/angelqba.image_to_scene/processors/processor_interface.gd"

var previous_layer
var heigth_scale
var total_scale
var mult

func _init().():
	processor_name = 'SimpleWaterProcessor'
	processor_type = 'water'

func process(layers, current_layer, current_result, selected_node):
	heigth_scale = selected_node.heigth_scale
	total_scale = selected_node.total_scale
	mult = heigth_scale * total_scale
	previous_layer = current_result['layers'].back()
	
	# do parent process
	var result = .process(layers, current_layer, current_result, selected_node)
	
	var min_y = null
	
	# search for min y value of previous layer
	for z in range(0, height):
		for x in range(0, width):
			var no_previous_point = false
			for pg in previous_layer['point_groups']:
				for result_pg in result['point_groups']:
					if pg[x][z] and result_pg[x][z]:
#						var tmp = pg[x][z]['vector'].y
#						pg[x][z]['vector'].y -= result_pg[x][z]['vector'].y
#						result_pg[x][z]['vector'].y = tmp
						if min_y == null or min_y > pg[x][z]['vector'].y:
							min_y = pg[x][z]['vector'].y
							
					else:
						no_previous_point = true

			if no_previous_point:
				continue
	
	# modify previous layer, lowering it
	for z in range(0, height):
		for x in range(0, width):
			var no_previous_point = false
			for pg in previous_layer['point_groups']:
				for result_pg in result['point_groups']:
					if pg[x][z] and result_pg[x][z]:
#						var tmp = pg[x][z]['vector'].y
						pg[x][z]['vector'].y = min_y - result_pg[x][z]['vector'].y
						result_pg[x][z]['vector'].y = min_y
					else:
						no_previous_point = true

			if no_previous_point:
				continue
	
	return result

# override parent function
func get_y(r, g, b):
	return 255 * 3 * mult - (r + g + b) * mult
