extends Node

# return Image from TIFF image path
func load_tiff_image(path):
	var result = load_tiff(path)
	return load_tiff_image_from_data(result)
	
# Converts TIFF parsed data in godot's Image
func load_tiff_image_from_data(data):
	var final_image: Image = null
	for i in data:
		var image = get_image_from_layer_data(i)
		
		if not final_image:
			final_image = Image.new()
			final_image.copy_from(image)
		else:
			final_image.blend_rect(image, Rect2(Vector2.ZERO, Vector2(i['ImageWidth'], i['ImageLength'])), Vector2.ZERO)
			
	return final_image
	
# Converts only one layer of TIFF parsed data in godot's Image
func get_image_from_layer_data(layer_data):
	var image: Image = Image.new()
	var format
	
	if layer_data['SamplesPerPixel'] == 3:
		format = Image.FORMAT_RGB8
	if layer_data['SamplesPerPixel'] == 4:
		format = Image.FORMAT_RGBA8
		
	image.create_from_data(
		layer_data['ImageWidth'], 
		layer_data['ImageLength'], 
		false,
		format,
		layer_data['data']
	)
	return image

# returns TIFF image data parsed
func load_tiff(path):
	var f = File.new()
	f.open(path, File.READ)
	var header = "%x" % f.get_16()
	if not header in ['4949', '4D4D']:
		print('This image is not a TIFF one')
		return
		
	f.get_16()
	var offset = f.get_32()
	f.seek(offset)
	var final_result = []
	while offset:
		var result = read_idf(f, offset)
		final_result.append(result)
		offset = result['new_offset']
		f.seek(offset)
		
	return final_result

# main parser of TIFF file
func read_idf(f: File, offset: int):
#	print()
#	print()
	if offset == 0:
		return
	
	var number_of_directory_entries = f.get_16()
		
	var PhotometricInterpretation = null
	var Compression = null
	var ImageLength = null
	var ImageWidth = null
	var RowsPerStrip = null
	var StripOffsets = []
	var StripByteCounts = []
	var PageName = ''
	var SamplesPerPixel = null
		
	for i in range(0, number_of_directory_entries):
		
		var tag = f.get_16()
		var field_type = f.get_16()
		var number_of_values = f.get_32()
		var value_offset = f.get_32()
		match tag:
			277:
				SamplesPerPixel = value_offset
			279:
				var current_position = f.get_position()
				if number_of_values == 1:
					StripByteCounts.append(value_offset)
				else:
					f.seek(value_offset)
					for z in range(0, number_of_values):
						var strip_byte_count
						if field_type == 4:
							strip_byte_count = f.get_32()
						if field_type == 3:
							strip_byte_count = f.get_16()
							
						StripByteCounts.append(strip_byte_count)
				
				f.seek(current_position)
			273:
				var current_position = f.get_position()
				if number_of_values == 1:
					StripOffsets.append(value_offset)
				else:
					f.seek(value_offset)
					for z in range(0, number_of_values):
						var strip_offset
						if field_type == 4:
							strip_offset = f.get_32()
						if field_type == 3:
							strip_offset = f.get_16()

						StripOffsets.append(strip_offset)
						
				f.seek(current_position)
			278:
				RowsPerStrip = value_offset
			285:  # nombre de la capa
				var current_position = f.get_position()
				
				f.seek(value_offset)
				PageName = ""
				for j in range(0, number_of_values):
					PageName += '%c' % f.get_8()
				
				f.seek(current_position)
			262:
				PhotometricInterpretation = value_offset
			259:
				Compression = value_offset
				if Compression != 1:
					print('TIFF image must be uncompressed')
					continue
			257:
				ImageLength = value_offset
			256:
				ImageWidth = value_offset
				
#		print('tag ', tag, ', ', 'field type ', field_type, ', ',  'number of values ', number_of_values, ', ', 'value offset ', value_offset)
	
	var new_offset = f.get_32()
	var data: PoolByteArray
	for i in len(StripOffsets):
		f.seek(StripOffsets[i])
		data.append_array(f.get_buffer(StripByteCounts[i]))
		
	return {
		'new_offset': new_offset,
		'PhotometricInterpretation': PhotometricInterpretation,
		'Compression': Compression,
		'ImageLength': ImageLength,
		'ImageWidth': ImageWidth,
		'RowsPerStrip': RowsPerStrip,
		'StripOffsets': StripOffsets,
		'StripByteCounts': StripByteCounts,
		'PageName': PageName,
		'SamplesPerPixel': SamplesPerPixel,
		'data': data
	}
