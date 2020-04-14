extends Node2D

func on_RestartButton_pressed():
	get_tree().change_scene("res://scenes/Main.tscn")

func on_RichTextLabel_meta_clicked(meta):
	OS.shell_open(meta)
