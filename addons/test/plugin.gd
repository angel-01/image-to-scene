tool
extends EditorPlugin

var object_processor: Node
var object_builder: Node
var registration_attempts = 10

func _enter_tree():
	# wait for the editor to load the main plugin
	get_tree().create_timer(1).connect("timeout", self, "register")
		
func register():
	var BuilderManager = get_tree().root.get_node("BuilderManager")
	var ProcessorManager = get_tree().root.get_node("ProcessorManager")
	
	object_builder = preload("res://addons/test/simple_object_builder.gd").new()
	object_processor = preload("res://addons/test/simple_object_processor.gd").new()
	
	if BuilderManager:
		# Register builders
		if not object_builder.builder_type in BuilderManager.builders:
			BuilderManager.builders[object_builder.builder_type] = {}
			
		BuilderManager.builders[object_builder.builder_type][object_builder.builder_name] = object_builder
		print('BuilderManager registered')
		
	else:
		print('No BuilderManager')
		if registration_attempts:
			registration_attempts -= 1
			get_tree().create_timer(1).connect("timeout", self, "register")
			return

	if ProcessorManager:
		# Register processors
		if not object_processor.processor_type in ProcessorManager.processors:
			ProcessorManager.processors[object_processor.processor_type] = {}
		
		ProcessorManager.processors[object_processor.processor_type][object_processor.processor_name] = object_processor
		print('ProcessorManager registered')
		
	else:
		print('No ProcessorManager')
		if registration_attempts:
			registration_attempts -= 1
			get_tree().create_timer(1).connect("timeout", self, "register")
			return

func _exit_tree():
	if object_builder:
		object_builder.queue_free()
		
	if object_processor:
		object_processor.queue_free()
