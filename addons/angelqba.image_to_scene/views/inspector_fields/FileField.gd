tool
extends "res://addons/angelqba.image_to_scene/views/inspector_fields/Field.gd"

var _file_dialog

func _enter_tree():
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_file_dialog.mode = FileDialog.MODE_OPEN_FILE
	if configuration:
		if 'masks' in configuration:
			var masks = []
			if not configuration['masks'] is Array:
				masks = [configuration['masks']]
			else:
				masks = configuration['masks']
				
			for m in masks:
				_file_dialog.add_filter(m)
		else:
			_file_dialog.add_filter("*.tscn ; TSCN files")
			
	_file_dialog.connect("file_selected", self, "_on_FileDialog_file_selected")
	_file_dialog.hide()
	get_tree().root.add_child(_file_dialog)
	
	if value:
		find_node('File').text = value
#	base_control.add_child(_file_dialog)

func _exit_tree():
	if _file_dialog != null:
		_file_dialog.queue_free()
		_file_dialog = null

func _on_Button_pressed():
	_file_dialog.popup_centered_ratio(0.7)

func _on_FileDialog_file_selected(fpath):
	value = fpath
	find_node('File').text = fpath
	emit_signal("on_value_changed", fpath)
