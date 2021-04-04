extends "res://addons/angelqba.image_to_scene/processors/processor_interface.gd"

func _init().():
	processor_name = 'SimpleObjectProcessor'
	processor_type = 'object'

func process(layers, current_layer, current_result, selected_node):
	var result = .process(layers, current_layer, current_result, selected_node)
	
	
	var grid = result['point_groups'][0]
	
	var visited = {}
#	var to_process = [grid[0][0]]
	var groups = []
#	print(to_process)
	
#	while to_process:
#		var current = to_process.pop_front()
		
	for x in result['width']:
		for z in result['height']:
			var current_position = Vector2(x, z)
#			print('current position: ', current_position)
			if current_position in visited:
				continue
			
			# escaneo zonas vacias
			if not grid[x][z]:
				var to_scan = [current_position]
				var group = {
					'type': 'empty',
					'elements': []
				}
				while to_scan:
#					print('to_scan: ', to_scan)
					var current = to_scan.pop_front()
					
					if current in visited:
						continue
					
					# si la posicion actual NO es vacia, no me interesa
					if grid[current.x][current.y]:
						continue
						
					if not current in visited:
						visited[current] = null
						
					var value = {
						"vector": current,
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
				
			else:
				var to_scan = [current_position]
				var group = {
					'type': 'filled',
					'elements': []
				}
				
				while to_scan:
#					print('to_scan: ', to_scan)
					var current = to_scan.pop_front()
					
					if current in visited:
						continue
					
					# si la posicion actual ESTA vacia, no me interesa
					if not grid[current.x][current.y]:
						continue
						
					if not current in visited:
						visited[current] = null
						
					var value = {
						"vector": current,
						"is_border": false
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
				
#	print("groups: ", groups)
	
	result['point_groups'] = groups
	return result
