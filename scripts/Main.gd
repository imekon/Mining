extends Node2D

const MINE_WIDTH = 64
const MINE_HEIGHT = 32
const MINE_CELL_SIZE = 32
const MINE_BAND1 = 90
const MINE_BAND2 = 92
const MINE_BAND3 = 95
const NUMBER_MONSTERS = 10

const NOISE_SEED_RANGE = 2048
const NOISE_OCTAVES = 2
const NOISE_PERIOD = 64
const NOISE_PERSISTANCE = 32
const NOISE_LACUNARITY = 1

const winning_limits = [ 3, 5, 5, 5, 7, 9 ]

onready var tilemap = $TileMap
onready var player = $Player
onready var mineral_label =$CanvasLayer/MineralLabel
onready var coal_label = $CanvasLayer/CoalLabel
onready var diamond_label = $CanvasLayer/DiamondsLabel
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

onready var explosion = $Sounds/Explosion

onready var Monster = load("res://scenes/Monster.tscn")
onready var Egg = load("res://scenes/Egg.tscn")

var mineral_score
var coal_score
var diamond_score
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
	mineral_score = 0
	coal_score = 0
	diamond_score = 0
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
	score_label.text = 'Score: ' + str(Global.player_score)
	mineral_label.text = 'Minerals: ' + str(mineral_score)
	coal_label.text = 'Coal: ' + str(coal_score)
	diamond_label.text = 'Diamonds: ' + str(diamond_score)
	
	if diamond_score == winning_limits[Global.player_winning]:
		start_new_game()
	
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
			damage_monster(monster, 1)
			return
			
	# check for eggs in the way
	for egg in eggs:
		if (egg.x == to_x) && (egg.y == to_y):
			damage_egg(egg)
			return
	
	var block = mine[to_y][to_x]
	if block == null:
		move_player(dx, dy)
		return
		
	if block.tile == 0:
		return
		
	if block.tile == 10:
		process_exploding_gas(to_x, to_y)
		return
	
	play_hit_sound()
	block.health -= 1
	
	digging_value = block.health * 100 / Block.tile_health[block.tile]
	
	if block.health <= 0:
		match block.tile:
			3:
				mineral_score += 1
			4:
				mineral_score += 2
			5:
				mineral_score += 3
			6:
				coal_score += 1
			7:
				diamond_score += 1

		destroy_block(Global.player_x + dx, Global.player_y + dy, block)
		move_player(dx, dy)
		
	set_digging_position()
	
func try_move_monster(monster):
	# print("try to move monster: " + str(monster.id))
	
	var to_x = monster.x + monster.dx
	var to_y = monster.y + monster.dy
	
	if (to_x < 1) || (to_x > MINE_WIDTH - 2) || (to_y < 1) || (to_y > MINE_HEIGHT - 2):
		# print("monster trying to move out of mine: " + str(monster.id))
		monster.reset_deltas()
		monster.goto_sleep()
		return
		
	if (to_x == Global.player_x) && (to_y == Global.player_y):
		# print("monster trying to move into player: " + str(monster.id))
		# monster.reset_deltas()
		return
		
	for other_monster in monsters:
		if other_monster.id == monster.id:
			continue
			
		if (to_x == other_monster.x) && (to_y == other_monster.y):
			# print("monster trying to move into other monster: " + str(monster.id))
			# monster.reset_deltas()
			return
	
	monster.x += monster.dx
	monster.y += monster.dy
	
	# print("monster moving " + str(monster.id) + ": " + str(monster.x) + ", " + str(monster.y))
	
	monster.reset_deltas()
	
	monster.position = Vector2(monster.x * 32, monster.y * 32)
	
func damage_monster(monster, damage):
	monster.health -= damage
	if monster.health <= 0:
		remove_child(monster)
		monsters.erase(monster)
		monster.queue_free()
	else:
		monster.wakeup(true)

	digging_value = 0
	set_digging_position()
	
func damage_egg(egg):
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
	
func process_exploding_gas(to_x, to_y):
	var hit_monsters = []
	var hit_eggs = []
	
	for y in range(to_y - 1, to_y + 2):
		for x in range(to_x - 1, to_x + 2):
			if mine[y][x] != null:
				if mine[y][x].tile != 0:
					mine[y][x] = null
					tilemap.set_cell(x, y, 1)
			
			for monster in monsters:
				if (monster.x == x) && (monster.y == y):
					hit_monsters.append(monster)
					
			for egg in eggs:
				if (egg.x == x) && (egg.y == y):
					hit_eggs.append(egg)
	
	for monster in hit_monsters:
		damage_monster(monster, 5)
		
	for egg in hit_eggs:
		damage_egg(egg)
		
	Global.player_score -= 100
	if Global.player_score < 0:
		Global.player_score = 0
		
	play_explosion_sound()
	
func play_hit_sound():
	if !enable_sounds:
		return
		
	var index = randi() % 5
	var hit = hit_sounds[index]
	hit.play()
	
func play_explosion_sound():
	if !enable_sounds:
		return

	explosion.play()
	
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
	Global.player_score += int(Block.tile_score[block.tile] * mask_scaling)
	mine[y][x] = null
	tilemap.set_cell(x, y, 1)
	block.queue_free()
	
func build_mine():
	var noise = OpenSimplexNoise.new()
	noise.seed = randi() % NOISE_SEED_RANGE
	noise.octaves = NOISE_OCTAVES
	noise.period = NOISE_PERIOD
	noise.persistence = NOISE_PERSISTANCE
	noise.lacunarity = NOISE_LACUNARITY
	
	for y in range(0, MINE_HEIGHT):
		var row = []
		for x in range(0, MINE_WIDTH):
			var tile = int((noise.get_noise_2d(x, y) + 1) * 1024) % 4 + 2

			var block = Block.new()

			var percent = randi() % 100
			if percent > MINE_BAND1:
				tile = randi() % 3 + 6

			if percent > MINE_BAND2:
				tile = 9
			
			if percent > MINE_BAND3:
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

func start_new_game():
	Global.player_winning += 1
	if Global.player_winning > winning_limits.size():
		Global.player_winning = winning_limits.size() - 1
		
	get_tree().change_scene("res://scenes/GameOver.tscn")
