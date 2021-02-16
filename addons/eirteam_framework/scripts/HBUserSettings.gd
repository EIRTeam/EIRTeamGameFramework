# User settings file class
extends HBSerializable

class_name HBUserSettings

var controller_guid = ""
var input_map = {}
var fps_limit: int = 180 # 0 is unlimited
var fullscreen = true


var master_volume = 1.0
var music_volume = 1.0
var sfx_volume = 1.0

var vsync_enabled = false

var button_prompt_override = "default"
var vibration_enabled = true

var button_prompt_override__possibilities = [
	"default",
	"xbox",
	"playstation",
	"nintendo"
]

var locale = "auto-detect"
var locale__possibilities = [
	"auto-detect",
	"en",
	"es",
	"ca"
]

func _init():

	serializable_fields += [
	"controller_guid", "input_map",
	"fps_limit", "fullscreen",
	"master_volume", "music_volume", "sfx_volume",
	"vsync_enabled", "button_prompt_override", "enable_vibration", "locale"]

static func deserialize(data: Dictionary):
	var result = .deserialize(data)
	result.input_map = {}
	if data.has("input_map"):
		for action_name in data.input_map:
			result.input_map[action_name] = []
			for action in data.input_map[action_name]:
				result.input_map[action_name].append(str2var(action))
	
	return result
	
func serialize(serialize_defaults=false):
	var base_data = .serialize()
	var new_input_map = {}
	for action_name in base_data.input_map:
		new_input_map[action_name] = []
		for action in base_data.input_map[action_name]:
			new_input_map[action_name].append(var2str(action))
	base_data.input_map = new_input_map

	return base_data
