class_name Piece
extends RefCounted

var id: int = 0
var state: int = 0
var show: bool = false
var x: Array = [0, 0, 0, 0]
var y: Array = [0, 0, 0, 0]

func _init() -> void:
	id = 0
	state = 0
	show = false
	x = [0, 0, 0, 0]
	y = [0, 0, 0, 0]

# 判断给定棋盘坐标是否属于该方块
func find_point(dx: int, dy: int) ->bool:
	for i in range(4):
		if(dx == x[i] and dy == y[i]):
			return true
	return false
