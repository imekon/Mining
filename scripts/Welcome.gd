extends Node2D

func on_StartButton_pressed():
	get_tree().change_scene("res://scenes/Main.tscn")

func on_InstructionsButton_pressed():
	get_tree().change_scene("res://scenes/Instructions.tscn")

func on_CreditsButton_pressed():
	get_tree().change_scene("res://scenes/Credits.tscn")
