extends Node

var _found_user_classes = {}
var _serializable_classes = {}
var _script_path_to_serializable_name = {}

func class_inherits_from(c_n: String, parent_class: String):
	if _found_user_classes[c_n].base == parent_class:
		return true
	elif _found_user_classes[c_n].base in _found_user_classes:
		return class_inherits_from(_found_user_classes[c_n].base, parent_class)
	else:
		return false

func _ready():
	for found_class in ProjectSettings.get("_global_script_classes"):
		_found_user_classes[found_class.class] = found_class
	for class_n in _found_user_classes:
		var inherits_from_serializable = class_inherits_from(class_n, "HBSerializable")
		if inherits_from_serializable:
			var script = load(_found_user_classes[class_n].path) as GDScript
			var serialized_type_name = class_n
			_script_path_to_serializable_name[_found_user_classes[class_n].path] = serialized_type_name
			# Users can specify their own serialized type names, else the 
			# class_name is used
			var script_instance = script.new()
			if script_instance.get_serialized_type():
				serialized_type_name = script_instance.get_serialized_type()
			_serializable_classes[serialized_type_name] = script
