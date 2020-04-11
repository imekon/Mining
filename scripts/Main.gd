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

onready var Monster = load("res://scenes/Monster.tscn")

var player_x
var player_y
var player_score

var digging_value

var mine = []

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
	player_x = randi() % (MINE_WIDTH - 2) + 1
	player_y = 1
	player_score = 0
	digging_value = 0
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
	
func try_move_player(dx, dy):
	var block = mine[player_y + dy][player_x + dx]
	if block == null:
		move_player(dx, dy)
		return
		
	if block.tile == 0:
		return
	
	block.health -= 1
	
	digging_value = block.health * 100 / Block.tile_health[block.tile]
	
	if block.health <= 0:
		destroy_block(player_x + dx, player_y + dy, block)
		move_player(dx, dy)
		
	set_digging_position()
		
func move_player(dx, dy):
	player_x += dx
	player_y += dy
	set_player_position()
	
func set_player_position():
	player.position.x = player_x * MINE_CELL_SIZE
	player.position.y = player_y * MINE_CELL_SIZE
	
func set_digging_position():
	if digging_value == 0:
		digging_label.visible = false
		digging_progress.visible = false
		return
		
	digging_label.visible = true
	digging_progress.visible = true
	digging_progress.value = digging_value
	
func destroy_block(x, y, block):
	player_score += Block.tile_score[block.tile]
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
			else:
				if percent > 90:
					tile = 9
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
				if j + y < MINE_HEIGHT - 2 && i + x < MINE_WIDTH - 2:
					mine[j + y][i + x] = null
				
	for i in range(0, MINE_HEIGHT):
		mine[i][0].tile = 0
		mine[i][MINE_WIDTH - 1].tile = 0
		
	for i in range(0, MINE_WIDTH):
		mine[0][i].tile = 0
		mine[MINE_HEIGHT - 1][i].tile = 0
		
	mine[player_y][player_x] = null
	
	for i in range(0, NUMBER_MONSTERS):
		var monster = Monster.instance()
		var keep_looking = true
		var x
		var y
		while keep_looking:
			x = randi() % (MINE_WIDTH - 2) + 1
			y = randi() % (MINE_HEIGHT - 2) + 1
			keep_looking = mine[y][x] == null
		
		monster.position = Vector2(x * 32, y * 32)
		add_child(monster)
		
	for y in range(0, MINE_HEIGHT):
		for x in range(0, MINE_WIDTH):
			if mine[y][x] != null:
				tilemap.set_cell(x, y, mine[y][x].tile)
