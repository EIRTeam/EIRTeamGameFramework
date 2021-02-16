# Main Game class
extends Node

var demo_mode = false

var game_theme: HBGameTheme = HBExampleGameTheme.new()

func _ready():
	_game_init()
	if "--demo-mode" in OS.get_cmdline_args():
		demo_mode = true
		
func _game_init():
	var args = OS.get_cmdline_args()
#	UserSettings._init_user_settings()
