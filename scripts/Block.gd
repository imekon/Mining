extends Node

class_name Block

const tile_health = [ 0, 0, 1, 2, 3, 5, 8, 8, 8, 8 ]
const tile_score = [ 0, 0, 0, 5, 10, 20, 50, 100, 0, 0, 0 ]

var tile
var health

func _init():
	tile = -1
	health = -1

func setup():
	health = tile_health[tile]
