tool
extends EditorPlugin

var object_processor: Node
var object_builder: Node
var registration_attempts = 10

func _enter_tree():
	# wait for the editor to load the main plugin
	get_tree().create_timer(1).connect("timeout", self, "register")
		
func register():
	# get managers
	var BuilderManager = get_tree().root.get_node("BuilderManager")
	var ProcessorManager = get_tree().root.get_node("ProcessorManager")
	
	# create an instance of the builder and the processor
	object_builder = preload("res://addons/angelqba.I2S.simple_object/simple_object_builder.gd").new()
	object_processor = preload("res://addons/angelqba.I2S.simple_object/simple_object_processor.gd").new()
	
	# if the build manager is already registered
	if BuilderManager:
		# Register builders
		if not object_builder.builder_type in BuilderManager.builders:
			BuilderManager.builders[object_builder.builder_type] = {}
			
		BuilderManager.builders[object_builder.builder_type][object_builder.builder_name] = object_builder
		
	# if the build manager is not regestered, wait 1 more second and retry 
	else:
		if registration_attempts:
			registration_attempts -= 1
			get_tree().create_timer(1).connect("timeout", self, "register")
			return

	# if the processor manager is already registered
	if ProcessorManager:
		# Register processors
		if not object_processor.processor_type in ProcessorManager.processors:
			ProcessorManager.processors[object_processor.processor_type] = {}
		
		ProcessorManager.processors[object_processor.processor_type][object_processor.processor_name] = object_processor
	
	# if the processor manager is not regestered, wait 1 more second and retry 
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
