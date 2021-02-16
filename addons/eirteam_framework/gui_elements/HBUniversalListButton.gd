extends HBUniversalListItem

class_name HBUniversalListButton

onready var button: Button = Button.new()

export(String) var text = "" setget set_text

func set_text(_text):
	text = _text
	if button:
		button.text = text

func _ready():
	add_child(button)
	set_text(text)
	button.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	button.connect("minimum_size_changed", self, "_on_button_minimum_size_changed")
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	mouse_filter = MOUSE_FILTER_IGNORE
	_on_button_minimum_size_changed()
	
func _on_button_minimum_size_changed():
	rect_min_size = button.get_minimum_size()
	rect_size = button.get_minimum_size()

func hover():
	button.add_stylebox_override("normal", get_stylebox("pressed", "Button"))

func stop_hover():
	button.add_stylebox_override("normal", get_stylebox("normal", "Button"))
