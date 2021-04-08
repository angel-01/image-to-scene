tool
extends MarginContainer

signal on_value_changed

var value = null

func set_title(title):
	var title_component = find_node('Title')
	title_component.text = title

func set_value(value):
	self.value = value

