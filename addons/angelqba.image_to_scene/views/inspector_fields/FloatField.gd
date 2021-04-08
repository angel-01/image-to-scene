tool
extends "res://addons/angelqba.image_to_scene/views/inspector_fields/Field.gd"

var input

func _enter_tree():
	input = find_node('Input')
	print('input: ', input)
	print('value: ', value)
	if value:
		input.value = value

func _on_Input_value_changed(value):
	value = value
	emit_signal("on_value_changed", value)
