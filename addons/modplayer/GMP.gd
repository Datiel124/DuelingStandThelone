"""
	Godot Mod Player Plugin by arlez80 (Yui Kinomoto)
"""

tool
extends EditorPlugin

func _enter_tree( ):
	#self.add_custom_type( "GodotModPlayer", "Spatial", preload("ModPlayer.gd"), preload("icon.png") )
	pass

func _exit_tree( ):
	#self.remove_custom_type( "GodotModPlayer" )
	pass

func has_main_screen():
	return true

func make_visible( visible:bool ):
	pass

func get_plugin_name( ):
	return "Godot Mod Player"
