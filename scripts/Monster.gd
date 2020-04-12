extends Node2D

const MONSTER_WAKEUP_TIME = 0.7

enum State { Asleep, Random, Fleeing }

var health = 10
var state = State.Asleep
var x = 0
var y = 0
var dx = 0
var dy = 0
var time = 0

func _ready():
	pass
	
func _process(delta):
	time += delta
	
	if time > MONSTER_WAKEUP_TIME:
		match state:
			State.Random:
				move_randomly()
			
			State.Fleeing:
				move_relative_player()
				
		time = 0
	
func wakeup(flee):
	if flee:
		state = State.Fleeing
	else:
		state = State.Random

func move_randomly():
	dx = 1 - randi() % 3
	dy = 1 - randi() % 3
	
func move_relative_player():
	dx = clamp(x - Global.player_x, -1, 1)
	dy = clamp(y - Global.player_y, -1, 1)
	
func reset_deltas():
	dx = 0
	dy = 0
