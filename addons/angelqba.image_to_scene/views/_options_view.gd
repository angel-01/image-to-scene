tool
extends Control

signal pattern_selected(pattern_index)
signal pattern_added(path)
signal pattern_removed(path)

onready var _item_list : ItemList = get_node("VBoxContainer/ItemList")

var _file_dialog = null
var _preview_provider : EditorResourcePreview = null
#var base_control = null

signal update_image_preview
signal update_model
signal layer_selected


func _on_ItemList_item_selected(index):
	emit_signal("layer_selected", index)

func _on_Update_pressed():
	emit_signal("update_image_preview")

func _on_UpdateModel_pressed():
	emit_signal('update_model')
