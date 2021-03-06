extends ScrollContainer

class_name HBUniversalScrollList

signal out_from_bottom
signal selected_item_changed

export(NodePath) var container_path
export(int) var horizontal_step = 1
export(int) var vertical_step = 1
export(bool) var enable_fade = false
export (bool) var enable_wrap_around = false
# When selecting an item, n HBHovereableItems before and after the selected one will
# receive a visibility report
export(int) var items_to_report_visibility_to = 6

enum SCROLL_MODE {
	PAGE,
	CENTER
}

export(SCROLL_MODE) var scroll_mode = SCROLL_MODE.PAGE

const FADE_SHADER = preload("res://addons/eirteam_framework/shaders/ScrollListFadeshader.shader")
var MOVE_SOUND = HBGame.game_theme.ui_press_sound
const INITIAL_DEBOUNCE_WAIT = 0.3
const DEBOUNCE_WAIT = 0.1


var debounce_step = 0
var target_scroll = 0.0
var current_selected_item = 0

onready var tween = Tween.new()
onready var initial_input_debounce_timer = Timer.new()
onready var input_debounce_timer = Timer.new()
onready var sfx_audio_player = AudioStreamPlayer.new()

onready var item_container: Control = get_node(container_path)

func _ready():
	add_child(tween)
	add_child(initial_input_debounce_timer)
	add_child(input_debounce_timer)
	add_child(sfx_audio_player)
	
	focus_mode = FOCUS_ALL
	
	sfx_audio_player.stream = MOVE_SOUND
	sfx_audio_player.bus = "SFX"
	
	initial_input_debounce_timer.wait_time = INITIAL_DEBOUNCE_WAIT
	initial_input_debounce_timer.one_shot = true
	initial_input_debounce_timer.connect("timeout", self, "_on_initial_input_debounce_timeout")
	input_debounce_timer.wait_time = DEBOUNCE_WAIT
	input_debounce_timer.connect("timeout", self, "_on_input_debounce_timeout")
	
	connect("focus_exited", self, "_on_focus_lost")
	connect("focus_entered", self, "_on_focus_entered")
	connect("resized", self, "_on_resized")
	
	get_v_scrollbar().connect("visibility_changed", self, "_on_vscrollbar_visibility_changed")
	get_v_scrollbar().connect("changed", self, "update_fade")
	get_v_scrollbar().connect("changed", self, "_on_scroll_changed")
	item_container.connect("resized", self, "force_scroll")
	if enable_fade:
		var fade_mat = ShaderMaterial.new()
		fade_mat.shader = FADE_SHADER
		material = fade_mat
	
	_on_resized()
	
func _on_scroll_changed():
	for i in range(item_container.get_child_count()):
		var child = item_container.get_child(i)
		if child.rect_position.y + child.rect_size.y >= scroll_vertical:
			for ii in range(child.get_position_in_parent() + items_to_report_visibility_to*2):
				if ii >= item_container.get_child_count():
					break
				var child2 = item_container.get_child(ii) as HBUniversalListItem
				if child2:
					child2._become_visible()
			break
	
func _on_initial_input_debounce_timeout():
	_position_change_input(debounce_step)
	input_debounce_timer.start()
	
func _on_input_debounce_timeout():
	_position_change_input(debounce_step)
	
func _on_vscrollbar_visibility_changed():
	if enable_fade:
		var mat = material as ShaderMaterial
		if mat:
			mat.set_shader_param("enabled", get_v_scrollbar().visible)
	
func _on_resized():
	if enable_fade:
		var mat = material as ShaderMaterial
		if mat:
			mat.set_shader_param("enabled", get_v_scrollbar().visible)
			mat.set_shader_param("size", rect_size)
			mat.set_shader_param("pos", rect_global_position)
			mat.set_shader_param("fade_size", 150.0 / float(rect_size.x))
func get_selected_item():
	if item_container.get_child_count() > current_selected_item and current_selected_item > -1:
		var item = item_container.get_child(current_selected_item)
		if item and is_instance_valid(item):
			return item
	return null
	
func smooth_scroll_to(target: float):
	tween.stop_all()
	tween.interpolate_property(self, "scroll_vertical", scroll_vertical, target, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	target_scroll = target
	tween.start()

func update_fade():
	# Hide top/bottom fade intelligently
	if enable_fade:
		var mat = material as ShaderMaterial
		if mat:
			var max_scroll = get_v_scrollbar().max_value - rect_size.y
			var selected_item = get_selected_item()
			if selected_item:
				# This ensures that if the target is at the top the fade is disabled so it's visible
				mat.set_shader_param("top_enabled", clamp(target_scroll, 0, max_scroll) < get_selected_item().rect_position.y)
			else:
				mat.set_shader_param("top_enabled", target_scroll > 0)
				
			mat.set_shader_param("bottom_enabled", target_scroll < max_scroll)
	
func select_item(item_i: int):
	var current_item = get_selected_item()
	
	var old_selected_item = current_selected_item
	
	if current_item:
		item_container.get_child(current_selected_item).stop_hover()
	
	var child = item_container.get_child(item_i)

	current_selected_item = item_i
	match scroll_mode:
		SCROLL_MODE.PAGE:
			if child.rect_position.y + child.rect_size.y > scroll_vertical + rect_size.y or \
					child.rect_position.y < scroll_vertical:
				smooth_scroll_to(float(child.rect_position.y))
		SCROLL_MODE.CENTER:
			smooth_scroll_to(float(child.rect_position.y + child.rect_size.y / 2.0 - rect_size.y / 2.0))
	if child.has_method("hover") and has_focus():
		child.hover()
	if old_selected_item != current_selected_item:
		emit_signal("selected_item_changed")
	if items_to_report_visibility_to > 0:
		var item_visiblity_report_min = current_selected_item - items_to_report_visibility_to
		item_visiblity_report_min = max(item_visiblity_report_min, 0)
		var item_visibility_report_max = current_selected_item + items_to_report_visibility_to + 1
		item_visibility_report_max = min(item_visibility_report_max, item_container.get_child_count())
		for i in range(item_visiblity_report_min, item_visibility_report_max):
			var visible_child = item_container.get_child(i)
			if visible_child is HBUniversalListItem:
				visible_child._become_visible()
	call_deferred("update_fade")
	
func force_scroll():
	if get_selected_item():
		select_item(current_selected_item)
	
func _input(event):
	# Stop debouncing when buttons are released
	for action in ["gui_up", "gui_down", "gui_left", "gui_right"]:
		if event.is_action_released(action):
			initial_input_debounce_timer.stop()
			input_debounce_timer.stop()

# Receives position change input, select items as needed & plays back sounds
func _position_change_input(position_change: int):
	if position_change != 0:
		var new_pos = current_selected_item + position_change
		if enable_wrap_around:
			 new_pos = wrapi(new_pos, 0, item_container.get_child_count())
		if new_pos > item_container.get_child_count() - 1:
			emit_signal("out_from_bottom")
		else:
			new_pos = clamp(new_pos, 0, item_container.get_child_count() - 1)
			if new_pos != current_selected_item:
				select_item(new_pos)
				sfx_audio_player.play()

func _gui_input(event):
	var position_change = 0
	
	if event.is_action_pressed("gui_down"):
		if vertical_step != 0:
			position_change += vertical_step
			get_tree().set_input_as_handled()
	if event.is_action_pressed("gui_up"):
		if vertical_step != 0:
			position_change -= vertical_step
			get_tree().set_input_as_handled()
	if event.is_action_pressed("gui_right"):
		if horizontal_step != 0:
			position_change += horizontal_step
			get_tree().set_input_as_handled()
	if event.is_action_pressed("gui_left"):
		if horizontal_step != 0:
			position_change -= horizontal_step
			get_tree().set_input_as_handled()
	if event.is_action_pressed("gui_accept"):
		var selected_child = get_selected_item()
		if selected_child and selected_child.has_signal("pressed"):
			get_tree().set_input_as_handled()
			selected_child.emit_signal("pressed")
	_position_change_input(position_change)
	if position_change != 0:
		debounce_step = position_change
		initial_input_debounce_timer.stop()
		input_debounce_timer.stop()
		initial_input_debounce_timer.start()

func _on_focus_lost():
	var current_item = get_selected_item()
	if current_item:
		current_item.stop_hover()

func _on_focus_entered():
	var current_item = get_selected_item()
	if current_item:
		current_item.hover()
