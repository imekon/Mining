extends Node2D

const MONSTER_WAKEUP_TIME = 0.7

enum State { Asleep, Random, Fleeing }

var id = -1
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
				# print("monster set to random: " + str(id))
				move_randomly()
			
			State.Fleeing:
				# print("monster set to flee: " + str(id))
				move_relative_player()
				
		time = 0
	
func wakeup(flee):
	if flee:
		state = State.Fleeing
	else:
		state = State.Random
		
func is_awake():
	return state != State.Asleep

func move_randomly():
	var direction = randi() % 8
	
	match direction:
		0:
			dx = 0
			dy = -1
		1:
			dx = 1
			dy = -1
		2:
			dx = 1
			dy = 0
		3:
			dx = 1
			dy = 1
		4:
			dx = 0
			dy = 1
		5:
			dx = -1
			dy = 1
		6:
			dx = -1
			dy = 0
		7:
			dx = -1
			dy = -1
			
	# print("monster random " + str(id) + ": " + str(dx) + ", " + str(dy))
	
func move_relative_player():
	dx = clamp(x - Global.player_x, -1, 1)
	dy = clamp(y - Global.player_y, -1, 1)
	# print("monster relative player " + str(id) + ": " + str(dx) + ", " + str(dy))
	
func reset_deltas():
	dx = 0
	dy = 0

func goto_sleep():
	state = State.Asleep
