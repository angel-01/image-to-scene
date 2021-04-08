extends "res://addons/angelqba.image_to_scene/processors/processor_interface.gd"

func _init().():
	processor_name = 'SimpleObjectProcessor'
	processor_type = 'object'

func process(layers, current_layer, current_result, selected_node):
	var result = .process(layers, current_layer, current_result, selected_node)
	var grid = result['point_groups'][0]
	var visited = {}
	var groups = []
		
	for x in result['width']:
		for z in result['height']:
			var current_position = Vector2(x, z)
			if current_position in visited:
				continue
			
			# scan empty zones
			if not grid[x][z]:
				var to_scan = [current_position]
				var group = {
					'type': 'empty',
					'elements': []
				}
				while to_scan:
					var current = to_scan.pop_front()
					
					if current in visited:
						continue
					
					# continue if the current position is NOT empty
					if grid[current.x][current.y]:
						continue
						
					if not current in visited:
						visited[current] = null
						
					var value = {
						"vector": Vector2(
							current.x * selected_node.total_scale - width / 2 * selected_node.total_scale, 
							current.y * selected_node.total_scale - height / 2 * selected_node.total_scale
						),
						"is_border": false
					}
						
					if current.x == 0 or current.x == width - 1 or current.y == 0 or current.y == height - 1:
						value['is_border'] = true
					elif grid[current.x-1][current.y] or grid[current.x+1][current.y] or grid[current.x][current.y-1] or grid[current.x][current.y+1]:
						value['is_border'] = true
						
					if current.x > 0:
						to_scan.append(Vector2(current.x - 1, current.y))
						
					if current.x < width - 1:
						to_scan.append(Vector2(current.x + 1, current.y))
						
					if current.y > 0:
						to_scan.append(Vector2(current.x, current.y - 1))
						
					if current.y < height - 1:
						to_scan.append(Vector2(current.x, current.y + 1))
					
					group['elements'].append(value)
					
				groups.append(group)
				
			# scann filled zones
			else:
				var to_scan = [current_position]
				var group = {
					'type': 'filled',
					'elements': []
				}
				
				while to_scan:
					var current = to_scan.pop_front()
					
					if current in visited:
						continue
					
					# continue if the current position IS empty
					if not grid[current.x][current.y]:
						continue
						
					if not current in visited:
						visited[current] = null
						
					#find the higest value in previous layers
					var new_height = null
					for layer in current_result['layers']:
						
						for g in layer['point_groups']:
							if g is Array and current.x < len(g) and g[current.x] is Array and current.y < len(g[current.x]) and g[current.x][current.y] and g[current.x][current.y]['vector'] is Vector3:
								if new_height == null:
									new_height = g[current.x][current.y]['vector'].y
								else:
									new_height = max(new_height, g[current.x][current.y]['vector'].y)
						
						if new_height == null:
							new_height = 0
					
					var value = {
						"vector": Vector3(
							current.x * selected_node.total_scale - width / 2 * selected_node.total_scale, 
							new_height,
							current.y * selected_node.total_scale - height / 2 * selected_node.total_scale
						),
						"is_border": false,
						"probability": grid[current.x][current.y]['vector'].y
					}
					
					if current.x == 0 or current.x == width - 1 or current.y == 0 or current.y == height - 1:
						value['is_border'] = true
					elif not grid[current.x-1][current.y] or not grid[current.x+1][current.y] or not grid[current.x][current.y-1] or not grid[current.x][current.y+1]:
						value['is_border'] = true
						
					if current.x > 0:
						to_scan.append(Vector2(current.x - 1, current.y))
						
					if current.x < width - 1:
						to_scan.append(Vector2(current.x + 1, current.y))
						
					if current.y > 0:
						to_scan.append(Vector2(current.x, current.y - 1))
						
					if current.y < height - 1:
						to_scan.append(Vector2(current.x, current.y + 1))
					
					group['elements'].append(value)
					
				groups.append(group)
				
	result['point_groups'] = groups
	return result

# replaces the parent method. it will be multiplied by alpha chanel and it will
# be used as a probability of object creation
func get_y(r, g, b):
	return 1
