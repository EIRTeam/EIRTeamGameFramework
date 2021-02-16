tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Menu System", "Control", preload("gui_elements/HBMenu.gd"), null)
	add_custom_type("Submenu", "Control", preload("gui_elements/HBSubmenu.gd"), null)


func _exit_tree():
	remove_custom_type("Menu System")
	remove_custom_type("Submenu")
