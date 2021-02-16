extends Control

class_name HBSubmenu

signal change_to_menu(menu_name, disable_animation, args)
signal transition_finished()

onready var tween = Tween.new()

const TRANSITION_DURATION = 0.25

export(bool) var transitions_enabled = true
export(String) var right = ""
export(String) var fullscreen = ""
export(NodePath) var focus_owner_path
onready var focus_owner = get_node(focus_owner_path)

const TRANSITION_TYPE = Tween.TRANS_QUAD

func _ready():
	add_child(tween)

	if transitions_enabled:
		tween.connect("tween_all_completed", self, "emit_signal", ["transition_finished"])
func change_to_menu(menu_name: String, disable_animation=false, args = {}):
	emit_signal("change_to_menu", menu_name, disable_animation, args)

func _on_menu_enter(disable_animation=false, args = {}):
	var starting_color = Color.white
	starting_color.a = 0.0
	var target_color = Color.white
	target_color.a = 1.0
	
	var starting_scale = Vector2(0.90, 0.90)
	var target_scale = Vector2.ONE
	
	var starting_position = (rect_size - rect_size*starting_scale) /2
	var target_position = Vector2(0.0, 0.0)
	
	if transitions_enabled and not disable_animation:
		tween.interpolate_property(self, "modulate", starting_color, target_color, TRANSITION_DURATION, TRANSITION_TYPE, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rect_scale", starting_scale, target_scale, TRANSITION_DURATION, TRANSITION_TYPE, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rect_position", starting_position, target_position, TRANSITION_DURATION, TRANSITION_TYPE, Tween.EASE_IN_OUT)
		tween.start()
	else:
		hide()
		emit_signal("transition_finished")
	if focus_owner:
		focus_owner.grab_focus()
func _on_menu_exit(disable_animation = false):
	var starting_color = Color.white
	starting_color.a = 1.0
	var target_color = Color.white
	target_color.a = 0.0
	var target_scale = Vector2(1.1, 1.1)
	var starting_scale = Vector2.ONE
	
	var starting_position = rect_position
	var target_position = (rect_size - rect_size*target_scale)/2
	
	
	if transitions_enabled and not disable_animation:
		tween.interpolate_property(self, "modulate", starting_color, target_color, TRANSITION_DURATION, TRANSITION_TYPE, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rect_scale", starting_scale, target_scale, TRANSITION_DURATION, TRANSITION_TYPE, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rect_position", starting_position, target_position, TRANSITION_DURATION, TRANSITION_TYPE, Tween.EASE_IN_OUT)
		tween.start()
	else:
		hide()
		emit_signal("transition_finished")
