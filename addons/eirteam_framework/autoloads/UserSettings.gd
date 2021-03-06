extends Node

var user_settings: HBUserSettings = HBUserSettings.new()

const USER_SETTINGS_PATH = "user://user_settings.json"
var base_input_map = {}

var debounce_timer = Timer.new()

signal controller_swapped(to_device)

var ACTION_CATEGORIES = {}

var action_names = {}

var axis_names = []

var button_names = []

const HIDE_KB_REMAPS_ACTIONS = [
	"gui_up",
	"gui_down",
	"gui_left",
	"gui_right",
	"gui_accept",
	"gui_cancel"
]

const DISABLE_ANALOG_FOR_ACTION = [
	"gui_accept",
	"gui_cancel",
]

var controller_device_idx = -1

func _ready():
	add_child(debounce_timer)
	debounce_timer.wait_time = 1.0
	debounce_timer.one_shot = true
	debounce_timer.connect("timeout", self, "_save_user_settings")

	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")

func _on_joy_connection_changed(device_idx: int, is_connected: bool):
	# fallback to controller 0
	if is_connected and Input.get_joy_guid(device_idx) == user_settings.controller_guid:
		print("Known controller connected, remapping...")
		map_actions_to_controller()

func get_input_map():
	var map = {}
	for action_name in InputMap.get_actions():
		if action_name in action_names:
			map[action_name] = []
			for event in InputMap.get_action_list(action_name):
				if event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventKey:
					map[action_name].append(event)
	return map
func _init_user_settings():
	load_user_settings()
	
	fill_localized_arrays()
	
	# Translation init
	if user_settings.locale != "auto-detect":
		TranslationServer.set_locale(user_settings.locale)
	
	base_input_map = get_input_map()

	apply_user_settings()
	# Set the controller to be the first one if we have none
	if Input.get_connected_joypads().size() > 0:
		if not user_settings.controller_guid:
			print("No information on last connected controller found, falling back to %s" % [Input.get_joy_guid(Input.get_connected_joypads()[0])])
			user_settings.controller_guid = Input.get_joy_guid(Input.get_connected_joypads()[0])
	load_input_map()

func fill_localized_arrays():
	button_names = [
		tr("DualShock Cross, Xbox A, Nintendo B"),
		tr("DualShock Circle, Xbox B, Nintendo A"),
		tr("DualShock Square, Xbox X, Nintendo Y"),
		tr("DualShock Triangle, Xbox Y, Nintendo X"),
		"L, L1",
		"R, R1",
		"L2",
		"R2",
		"L3",
		"R3",
		tr("Select, DualShock Share, Nintendo -"),
		tr("Start, DualShock Options, Nintendo +"),
		tr("D-Pad Up"),
		tr("D-Pad Down"),
		tr("D-Pad Left"),
		tr("D-Pad Right")
	]
	
	axis_names = [
		tr(" (Left Stick Left)"),
		tr(" (Left Stick Right)"),
		tr(" (Left Stick Up)"),
		tr(" (Left Stick Down)"),
		tr(" (Right Stick Left)"),
		tr(" (Right Stick Right)"),
		tr(" (Right Stick Up)"),
		tr(" (Right Stick Down)"),
		"", "", "", "",
		"", " (L2)",
		"", " (R2)"
	]
	
	action_names = {
		"note_up": tr("Note up"),
		"note_down": tr("Note down"),
		"note_left": tr("Note left"),
		"note_right": tr("Note right"),
		"gui_up": tr("Menu up"),
		"gui_down": tr("Menu down"),
		"gui_left": tr("Menu left"),
		"gui_right": tr("Menu right"),
		"gui_tab_left": tr("Tab left"),
		"gui_tab_right": tr("Tab right"),
		"gui_accept": tr("Menu accept"),
		"gui_cancel": tr("Menu cancel"),
		"contextual_option": tr("Contextual option"),
		"practice_set_waypoint": tr("Practice mode: Set waypoint"),
		"practice_go_to_waypoint": tr("Practice mode: Go to waypoint"),
		"slide_left": tr("Slide left"),
		"slide_right": tr("Slide right"),
		"heart_note": tr("Heart note"),
		"pause": tr("Pause")
	}
	
	ACTION_CATEGORIES = {
		tr("Notes"): ["note_up", "note_down", "note_left", "note_right", "slide_left", "slide_right", "heart_note"],
		tr("Game"): ["pause", "practice_set_waypoint", "practice_go_to_waypoint"],
		tr("GUI"): ["gui_up", "gui_down", "gui_left", "gui_right", "gui_tab_left", "gui_tab_right", "gui_accept", "gui_cancel", "contextual_option"]
	}
func get_axis_name(event: InputEventJoypadMotion):
	var n = 2 * event.axis;
	if event.axis_value >= 0:
		n += 1
	var axis_sign = "+"
	if event.axis_value < 0:
		axis_sign = "-"
	return "Axis " + str(event.axis) + " " + axis_sign + " " + axis_names[n]

func get_button_name(event: InputEventJoypadButton):
	return button_names[event.button_index]

func load_input_map():
	# Loads input map from the user's settings
	for action_name in user_settings.input_map:
		if InputMap.has_action(action_name):
			InputMap.action_erase_events(action_name)
			for action in user_settings.input_map[action_name]:
				InputMap.action_add_event(action_name, action)
	# if we don't have a device idx we try to use the stored guid one, else we use
	# the first one
	if controller_device_idx == -1:
		var found_stored_guid_device = false
		for _device_idx in Input.get_connected_joypads():
			if Input.get_joy_guid(_device_idx) == user_settings.controller_guid:
				found_stored_guid_device = true
				break
		if not found_stored_guid_device:
			controller_device_idx = 0
			if Input.get_connected_joypads().size() > 0:
				user_settings.controller_guid = Input.get_joy_guid(Input.get_connected_joypads()[0])
	map_actions_to_controller()
func map_actions_to_controller():
	for _device_idx in Input.get_connected_joypads():
		if Input.get_joy_guid(_device_idx) == user_settings.controller_guid:
			print("Swapping main controller device from " + str(controller_device_idx) + " to " + str(_device_idx))
			controller_device_idx = _device_idx
			break
	# Remap actions to new device id
	for action_name in action_names:
		for event in InputMap.get_action_list(action_name):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action_name, event)
				event.device = controller_device_idx
				InputMap.action_add_event(action_name, event)
	JoypadSupport._set_joypad(controller_device_idx, true)
	
	if Input.get_connected_joypads().size() == 0:
		JoypadSupport.force_keyboard_prompts()
	
	emit_signal("controller_swapped", controller_device_idx)
	
enum PROMPT_MODE {
	KEYBOARD,
	JOYPAD
}
	
var current_mode = PROMPT_MODE.KEYBOARD
func _input(event):
	if event is InputEventJoypadButton:
		if current_mode != PROMPT_MODE.JOYPAD:
			current_mode = PROMPT_MODE.JOYPAD
			JoypadSupport._set_joypad(event.device, true)
			set_joypad_prompts()
	elif event is InputEventKey:
		if current_mode != PROMPT_MODE.KEYBOARD:
			current_mode = PROMPT_MODE.KEYBOARD
			JoypadSupport.set_autodetect_to(true)
			JoypadSupport.set_chosen_skin(JS_JoypadIdentifier.JoyPads.UNINDENTIFIED)
			JoypadSupport.force_keyboard_prompts()
func load_user_settings():
	var file := File.new()
	var usp = USER_SETTINGS_PATH
	if file.file_exists(usp):
		if file.open(usp, File.READ) == OK:
			var result = JSON.parse(file.get_as_text())
			if result.error == OK:
				user_settings = HBUserSettings.deserialize(result.result)
				print("Successfully loaded user settings from " + usp)
			else:
				print("Error loading user settings, on line %d: %s" % [result.error_line, result.error_string])
	
func set_joypad_prompts():
	match user_settings.button_prompt_override:
		"default":
			JoypadSupport.set_autodetect_to(true)
			JoypadSupport.set_chosen_skin(JS_JoypadIdentifier.JoyPads.UNINDENTIFIED)
		"xbox":
			JoypadSupport.set_autodetect_to(false)
			JoypadSupport.set_chosen_skin(JS_JoypadIdentifier.JoyPads.XBOX)
		"playstation":
			JoypadSupport.set_autodetect_to(false)
			JoypadSupport.set_chosen_skin(JS_JoypadIdentifier.JoyPads.PLAYSTATION)
		"nintendo":
			JoypadSupport.set_autodetect_to(false)
			JoypadSupport.set_chosen_skin(JS_JoypadIdentifier.JoyPads.NINTENDO)
func apply_user_settings():
	Input.set_use_accumulated_input(!user_settings.input_poll_more_than_once_per_frame)
	set_fullscreen(user_settings.fullscreen)
	Engine.target_fps = int(user_settings.fps_limit)
	OS.vsync_enabled = user_settings.vsync_enabled
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, user_settings.visualizer_enabled)
	set_volumes()

func save_user_settings():
	debounce_timer.start(0)
func _save_user_settings():
	var file := File.new()
	user_settings.input_map = get_input_map()
	if file.open(USER_SETTINGS_PATH, File.WRITE) == OK:
		var contents = JSON.print(user_settings.serialize(), "  ")
		file.store_string(contents)

func get_event_name(event: InputEvent):
	var ret = ""
	if event is InputEventJoypadMotion:
		var _axis_sign = "+"
		if event.axis_value < 0:
			_axis_sign = "-"
		ret = get_axis_name(event)
	elif event is InputEventJoypadButton:
		ret = get_button_name(event)
	elif event is InputEventKey:
		ret = OS.get_scancode_string(event.scancode)
	return ret
	
func set_fullscreen(fullscreen = false):
	yield(get_tree(), "idle_frame")
	OS.window_borderless = fullscreen
	OS.window_fullscreen = fullscreen
	
func set_volumes():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(user_settings.master_volume * 0.186209))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(user_settings.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear2db(user_settings.sfx_volume))
	
func reset_to_default_input_map():
	user_settings.input_map = base_input_map
	load_input_map()
	save_user_settings()
