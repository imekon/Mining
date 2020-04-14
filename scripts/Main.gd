extends Node2D

const MINE_WIDTH = 64
const MINE_HEIGHT = 32
const MINE_CELL_SIZE = 32
const NUMBER_MONSTERS = 10

onready var tilemap = $TileMap
onready var player = $Player
onready var score_label = $CanvasLayer/ScoreLabel
onready var digging_label = $CanvasLayer/DiggingLabel
onready var digging_progress = $CanvasLayer/DiggingProgress
onready var mask = $Player/Mask
onready var enable_sounds_button = $CanvasLayer/EnableSoundButton

onready var hit1 = $Sounds/Hit1
onready var hit2 = $Sounds/Hit2
onready var hit3 = $Sounds/Hit3
onready var hit4 = $Sounds/Hit4
onready var hit5 = $Sounds/Hit5

onready var Monster = load("res://scenes/Monster.tscn")
onready var Egg = load("res://scenes/Egg.tscn")

var player_score
var mask_scaling
var digging_value
var enable_sounds

var mine = []
var monsters = []
var eggs = []
var hit_sounds = []

# Tiles
# 0 - barrier, edge of the world
# 1 - empty
# 2 - ground
# 3-5 - rocks
# 6 - coal
# 7 - diamond
# 8 - sulphur
# 9 - gas (explosive if touched)

func _ready():
	randomize()
	Global.player_x = randi() % (MINE_WIDTH - 2) + 1
	Global.player_y = 1
	player_score = 0
	mask_scaling = 0.5
	digging_value = 0
	enable_sounds = true
	
	hit_sounds.append(hit1)
	hit_sounds.append(hit2)
	hit_sounds.append(hit3)
	hit_sounds.append(hit4)
	hit_sounds.append(hit5)
	
	set_player_position()
	set_digging_position()
	build_mine()
	
func _process(delta):
	score_label.text = 'Score: ' + str(player_score)
	
	var dx = 0
	var dy = 0
	
	if Input.is_action_just_pressed("left"):
		dx = -1
	if Input.is_action_just_pressed("right"):
		dx = 1
	if Input.is_action_just_pressed("up"):
		dy = -1
	if Input.is_action_just_pressed("down"):
		dy = 1
		
	try_move_player(dx, dy)
	
	for monster in monsters:
		if monster.is_awake():
			try_move_monster(monster)
			
	if mask_scaling < 1:
		mask_scaling += delta / 500
		mask.scale.x = mask_scaling
		mask.scale.y = mask_scaling
	
func try_move_player(dx, dy):
	var to_x = Global.player_x + dx
	var to_y = Global.player_y + dy
	
	# check for monsters in the way
	for monster in monsters:
		if (monster.x == to_x) && (monster.y == to_y):
			monster.health -= 1
			if monster.health <= 0:
				remove_child(monster)
				monsters.erase(monster)
				monster.queue_free()
			else:
				monster.wakeup(true)
			digging_value = 0
			set_digging_position()
			return
			
	# check for eggs in the way
	for egg in eggs:
		if (egg.x == to_x) && (egg.y == to_y):
			remove_child(egg)
			eggs.erase(egg)
			egg.queue_free()
			mask_scaling -= 0.1
			if mask_scaling < 0.5:
				mask_scaling = 0.5
			mask.scale.x = mask_scaling
			mask.scale.y = mask_scaling
			digging_value = 0
			set_digging_position()
			return
	
	var block = mine[to_y][to_x]
	if block == null:
		move_player(dx, dy)
		return
		
	if block.tile == 0:
		return
	
	play_hit_sound()
	block.health -= 1
	
	digging_value = block.health * 100 / Block.tile_health[block.tile]
	
	if block.health <= 0:
		destroy_block(Global.player_x + dx, Global.player_y + dy, block)
		move_player(dx, dy)
		
	set_digging_position()
	
func try_move_monster(monster):
	# print("try to move monster: " + str(monster.id))
	
	var to_x = monster.x + monster.dx
	var to_y = monster.y + monster.dy
	
	if (to_x < 1) || (to_x > MINE_WIDTH - 2) || (to_y < 1) || (to_y > MINE_HEIGHT - 2):
		print("monster trying to move out of mine: " + str(monster.id))
		monster.reset_deltas()
		monster.goto_sleep()
		return
		
	if (to_x == Global.player_x) && (to_y == Global.player_y):
		print("monster trying to move into player: " + str(monster.id))
		# monster.reset_deltas()
		return
		
	for other_monster in monsters:
		if other_monster.id == monster.id:
			continue
			
		if (to_x == other_monster.x) && (to_y == other_monster.y):
			print("monster trying to move into other monster: " + str(monster.id))
			# monster.reset_deltas()
			return
	
	monster.x += monster.dx
	monster.y += monster.dy
	
	print("monster moving " + str(monster.id) + ": " + str(monster.x) + ", " + str(monster.y))
	
	monster.reset_deltas()
	
	monster.position = Vector2(monster.x * 32, monster.y * 32)
	
func play_hit_sound():
	if !enable_sounds:
		return
		
	var index = randi() % 5
	var hit = hit_sounds[index]
	hit.play()
	
func move_player(dx, dy):
	Global.player_x += dx
	Global.player_y += dy
	set_player_position()
	
func set_player_position():
	player.position.x = Global.player_x * MINE_CELL_SIZE
	player.position.y = Global.player_y * MINE_CELL_SIZE
	
func set_digging_position():
	if digging_value == 0:
		digging_label.visible = false
		digging_progress.visible = false
		return
		
	digging_label.visible = true
	digging_progress.visible = true
	digging_progress.value = digging_value
	
func destroy_block(x, y, block):
	player_score += int(Block.tile_score[block.tile] * mask_scaling)
	mine[y][x] = null
	tilemap.set_cell(x, y, 1)
	block.queue_free()
	
func build_mine():
	for y in range(0, MINE_HEIGHT):
		var row = []
		for x in range(0, MINE_WIDTH):
			var block = Block.new()
			var tile = randi() % 4 + 2
			var percent = randi() % 100
			if percent > 80:
				tile = randi() % 3 + 6

			if percent > 90:
				tile = 9
			
			if percent > 95:
				tile = 10
				
			block.tile = tile
			block.setup()
			row.append(block)
		mine.append(row)
		
	for k in range(0, 3):
		var x = randi() % 48 + 1
		var y = randi() % 24 + 1
		var w = randi() % 16 + 8
		var h = randi() % 12 + 4
		
		for j in range(0, h):
			for i in range(0, w):
				if (j + y < MINE_HEIGHT - 2) && (i + x < MINE_WIDTH - 2):
					mine[j + y][i + x] = null
				
	for i in range(0, MINE_HEIGHT):
		mine[i][0].tile = 0
		mine[i][MINE_WIDTH - 1].tile = 0
		
	for i in range(0, MINE_WIDTH):
		mine[0][i].tile = 0
		mine[MINE_HEIGHT - 1][i].tile = 0
		
	mine[Global.player_y][Global.player_x] = null
	
	for i in range(0, NUMBER_MONSTERS):
		var keep_looking = true
		var x
		var y
		while keep_looking:
			x = randi() % (MINE_WIDTH - 2) + 1
			y = randi() % (MINE_HEIGHT - 2) + 1
			keep_looking = mine[y][x] == null
		
		var monster = Monster.instance()
		monster.id = i
		monster.x = x
		monster.y = y
		monster.position = Vector2(x * 32, y * 32)
		monsters.append(monster)
		add_child(monster)
		
	monsters[0].wakeup(false)
	
	for i in range(0, 30):
		var keep_looking = true
		var x
		var y
		while keep_looking:
			x = randi() % (MINE_WIDTH - 2) + 1
			y = randi() % (MINE_HEIGHT - 2) + 1
			keep_looking = mine[y][x] != null
		
		var egg = Egg.instance()
		egg.x = x
		egg.y = y
		egg.position = Vector2(x * 32, y * 32)
		eggs.append(egg)
		add_child(egg)
	
	for y in range(0, MINE_HEIGHT):
		for x in range(0, MINE_WIDTH):
			if mine[y][x] != null:
				tilemap.set_cell(x, y, mine[y][x].tile)


func on_EnableSoundButton_pressed():
	enable_sounds = enable_sounds_button.pressed

func on_ReadmeButton_pressed():
	get_tree().change_scene("res://scenes/Instructions.tscn")
