extends Control

class_name HBMenu

export(String) var starting_menu = "start_menu"
var starting_menu_args = []
var background_transition_animation_player: AnimationPlayer
var first_background_texrect: TextureRect
var second_background_texrect: TextureRect

const BACKGROUND_TRANSITION_TIME = 0.25 # seconds

signal change_to_submenu(menu_name)

var submenu_scenes = {}

func change_to_submenu(submenu_name: String, disable_animation=false, args = {}):
	if not submenu_name in submenu_scenes:
#		Log.log(self, "Error loading menu %s, menu not found" % menu_name, Log.LogLevel.ERROR)
		return
	emit_signal("change_to_submenu", submenu_name, disable_animation, args)

func add_submenu(submenu: HBSubmenu):
	submenu_scenes[submenu.name] = submenu
	if not submenu in get_children():
		add_child(submenu)
	remove_child(submenu)
var fullscreen_menu
var left_menu
var right_menu

export(NodePath) var left_container_path
export(NodePath) var right_container_path
export(NodePath) var fullscreen_container_path

onready var fullscreen_menu_container: Control = get_node(fullscreen_container_path)
onready var left_menu_container: Control = get_node(left_container_path)
onready var right_menu_container: Control = get_node(right_container_path)

func _ready():
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920, 1080))
	connect("change_to_submenu", self, "_on_change_to_submenu")
	
	for child in get_children():
		if child is HBSubmenu:
			add_submenu(child)
	
	menu_setup()

func _on_loading_begun():
	pass

func menu_setup():
	change_to_submenu(starting_menu, false, starting_menu_args)

func _on_change_to_submenu(menu_name: String, force_hard_transition=false, args = {}):
	#Log.log(self, "Changing to menu " + menu_name)
	var menu_data = submenu_scenes[menu_name]
	
	if left_menu:
		left_menu._on_menu_exit(force_hard_transition)
		left_menu.connect("transition_finished", left_menu_container, "remove_child", [left_menu], CONNECT_ONESHOT)
	if right_menu and ("right" in menu_data or "fullscreen" in menu_data) and ("fullscreen" in menu_data or not right_menu == submenu_scenes[menu_data.right].right):
		right_menu._on_menu_exit(force_hard_transition)
		right_menu.connect("transition_finished", right_menu_container, "remove_child", [right_menu], CONNECT_ONESHOT)
	
	if fullscreen_menu:
		fullscreen_menu._on_menu_exit(force_hard_transition)
		fullscreen_menu.connect("transition_finished", fullscreen_menu_container, "remove_child", [fullscreen_menu], CONNECT_ONESHOT)
		fullscreen_menu = null
	if menu_data.fullscreen:
		fullscreen_menu = submenu_scenes[menu_data.fullscreen]
		fullscreen_menu_container.add_child(fullscreen_menu)
		fullscreen_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
		fullscreen_menu._on_menu_enter(force_hard_transition, args)
	if menu_data.right:
		right_menu = submenu_scenes[menu_data.right] as HBSubmenu
		# Prevent softlock when transiton hasn't finished
		if right_menu.is_connected("transition_finished", right_menu_container, "remove_child"):
			right_menu.disconnect("transition_finished", right_menu_container, "remove_child")
		if not right_menu in right_menu_container.get_children():
			# Right side of menus are single instance if they are the same
			if not right_menu in right_menu_container.get_children():
				right_menu_container.add_child(right_menu)
	#		right_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
			right_menu._on_menu_enter(force_hard_transition, args)

	if not menu_data.fullscreen:
		left_menu = menu_data
		# Prevent softlock when transiton hasn't finished
		if left_menu.is_connected("transition_finished", left_menu_container, "remove_child"):
			left_menu.disconnect("transition_finished", left_menu_container, "remove_child")
		if not left_menu in left_menu_container.get_children():
			left_menu_container.add_child(left_menu)

		left_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
		left_menu._on_menu_enter(force_hard_transition, args)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		for menu in submenu_scenes:
			if is_instance_valid(submenu_scenes[menu]):
				submenu_scenes[menu].queue_free()
