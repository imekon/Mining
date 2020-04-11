extends Node2D

const MINE_WIDTH = 64
const MINE_HEIGHT = 32
const MINE_CELL_SIZE = 32

onready var tilemap = $TileMap
onready var player = $Player

var player_x
var player_y
var mine = []

func _ready():
	randomize()
	player_x = randi() % (MINE_WIDTH - 2) + 1
	player_y = 1
	set_player_position()
	build_mine()

func set_player_position():
	player.position.x = player_x * MINE_CELL_SIZE
	player.position.y = player_y * MINE_CELL_SIZE
	
func build_mine():
	for y in range(0, MINE_HEIGHT):
		var row = []
		for x in range(0, MINE_WIDTH):
			var block = Block.new()
			block.tile = randi() % 3 + 1
			block.health = 4
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
		
	for y in range(0, MINE_HEIGHT):
		for x in range(0, MINE_WIDTH):
			if mine[y][x] != null:
				tilemap.set_cell(x, y, mine[y][x].tile)
