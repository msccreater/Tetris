class_name XRS
extends RefCounted

var KICK_TABLE_JLSTZ = [
	[[-1, 0], [-1, 1], [0, -2], [-1, -2]],
	[[1, 0], [1, -1], [0, 2], [1, 2]],
	[[1, 0], [1, 1], [0, -2], [1, -2]],
	[[-1, 0], [-1, -1], [0, 2], [-1, 2]],
	[[1, 0], [1, 1], [0, -2], [1, -2]],
	[[1, 0], [1, -1], [0, 2], [1, 2]],
	[[-1, 0], [-1, 1], [0, -2], [-1, -2]],
	[[-1, 0], [-1, -1], [0, 2], [-1, 2]],
	[[-1, 0], [1, 0], [0, -1], [0, 1]],
	[[0, -1], [-1, 0], [1, 0], [0, 1]],
	[[1, 0], [-1, 0], [0, -1], [0, 1]],
	[[0, -1], [-1, 0], [1, 0], [0, 1]]
];

var KICK_TABLE_I = [
	[[1, 0], [-2, 0], [1, 2], [-2, -1]],
	[[-1, 0], [2, 0], [-1, 2], [2, -1]],
	[[-1, 0], [2, 0], [-1, -2], [2, 1]],
	[[1, 0], [-2, 0], [1, -2], [-2, 1]],
	[[-1, 0], [2, 0], [-1, 2], [2, -1]],
	[[-1, 0], [2, 0], [-1, -2], [2, 1]],
	[[1, 0], [-2, 0], [1, -2], [-2, 1]],
	[[1, 0], [-2, 0], [1, 2], [-2, -1]],
	[[-1, 0], [1, 0], [0, -1], [0, 1]],
	[[0, -1], [-1, 0], [1, 0], [0, 1]],
	[[1, 0], [-1, 0], [0, 1], [0, -1]],
	[[0, -1], [1, 0], [-1, 0], [0, 1]]
];

# ---------- 方块形状定义 ----------
#每个方块有4个旋转状态，每个状态存储4个小方格的相对坐标
#格式: [x0, x1, x2, x3, y0, y1, y2, y3] (原: a)
var PIECE_SHAPES = [
	# O 方块
	[
		[0, 0, 1, 1, 0, 1, 0, 1],
		[0, 0, 1, 1, 0, 1, 0, 1],
		[0, 0, 1, 1, 0, 1, 0, 1],
		[0, 0, 1, 1, 0, 1, 0, 1]
	],
	# Z 方块
	[
		[0, 1, 1, 2, 0, 1, 0, 1],
		[2, 1, 2, 1, 0, 1, 1, 2],
		[2, 1, 1, 0, 2, 1, 2, 1],
		[0, 1, 0, 1, 2, 1, 1, 0]
	],
	# S 方块
	[
		[0, 1, 1, 2, 1, 1, 0, 0],
		[1, 1, 2, 2, 0, 1, 1, 2],
		[2, 1, 1, 0, 1, 1, 2, 2],
		[1, 1, 0, 0, 2, 1, 1, 0]
	],
	# J 方块
	[
		[0, 0, 1, 2, 0, 1, 1, 1],
		[2, 1, 1, 1, 0, 0, 1, 2],
		[2, 2, 1, 0, 2, 1, 1, 1],
		[0, 1, 1, 1, 2, 2, 1, 0]
	],
	# L 方块
	[
		[2, 2, 1, 0, 0, 1, 1, 1],
		[2, 1, 1, 1, 2, 2, 1, 0],
		[0, 0, 1, 2, 2, 1, 1, 1],
		[0, 1, 1, 1, 0, 0, 1, 2]
	],
	# T 方块
	[
		[0, 1, 1, 2, 1, 1, 0, 1],
		[1, 1, 2, 1, 0, 1, 1, 2],
		[2, 1, 1, 0, 1, 1, 2, 1],
		[1, 1, 0, 1, 2, 1, 1, 0]
	],
	# I 方块
	[
		[0, 1, 2, 3, 1, 1, 1, 1],
		[2, 2, 2, 2, 0, 1, 2, 3],
		[3, 2, 1, 0, 2, 2, 2, 2],
		[1, 1, 1, 1, 3, 2, 1, 0]
	]
];

func can_rotate_right(piece: Piece, matrix: Array[Array], offsetX: int = 0, offsetY: int = 0) -> bool:
	if piece.id == 0: return false
	
	var shapes = PIECE_SHAPES[piece.id]
	var state = piece.state
	var newX = [0, 0, 0, 0]
	var newY = [0, 0, 0, 0]

	var baseX: int = piece.x[0] - shapes[state][0] + offsetX
	var baseY: int = piece.y[0] - shapes[state][4] - offsetY

	var newState = state + 1
	if newState >= 4: newState = 0

	for i in range(4):
		newX[i] = shapes[newState][i] + baseX
		newY[i] = shapes[newState][i + 4] + baseY

	for i in range(4):
		if matrix[newY[i]] == null: return false
		if newX[i] < 0: return false
		if newX[i] > 9: return false
		if matrix[newY[i]][newX[i]] >= 0: return false

	return true

func can_rotate_left(piece: Piece, matrix: Array[Array], offsetX: int = 0, offsetY: int = 0) -> bool:
	if piece.id == 0: return false

	var shapes = PIECE_SHAPES[piece.id]
	var state = piece.state
	var newX = [0, 0, 0, 0]
	var newY = [0, 0, 0, 0]

	var baseX = piece.x[0] - shapes[state][0] + offsetX
	var baseY = piece.y[0] - shapes[state][4] - offsetY

	var newState = state - 1
	if newState < 0: newState = 3

	for i in range(4):
		newX[i] = shapes[newState][i] + baseX
		newY[i] = shapes[newState][i + 4] + baseY

	for i in range(4):
		if matrix[newY[i]] == null: return false
		if newX[i] < 0: return false
		if newX[i] > 9: return false
		if matrix[newY[i]][newX[i]] >= 0: return false

	return true

func can_rotate_180(piece: Piece, matrix: Array[Array], offsetX: int = 0, offsetY: int = 0) -> bool:
	if piece.id == 0: return false

	var shapes = PIECE_SHAPES[piece.id]
	var state = piece.state
	var newX = [0, 0, 0, 0]
	var newY = [0, 0, 0, 0]

	var baseX = piece.x[0] - shapes[state][0] + offsetX
	var baseY = piece.y[0] - shapes[state][4] - offsetY

	var newState = (state + 2) % 4

	for i in range(4):
		newX[i] = shapes[newState][i] + baseX
		newY[i] = shapes[newState][i + 4] + baseY

	for i in range(4):
		if matrix[newY[i]] == null: return false
		if newX[i] < 0: return false
		if newX[i] > 9: return false
		if matrix[newY[i]][newX[i]] >= 0: return false

	return true

func init_shape(piece: Piece) -> void:
	# 各形状的 X 偏移量
	var xOffsets = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	# 各形状的 Y 偏移量
	var yOffsets = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

	piece.state = 0;
	var shapes = PIECE_SHAPES[piece.id]
	var state = piece.state

	for i in range(4):
		piece.x[i] = shapes[state][i] + 3 + xOffsets[piece.id]
		piece.y[i] = shapes[state][i + 4] + 3 + yOffsets[piece.id + 7] + 8 - 4 - 1

func test_kick_right(piece: Piece, matrix: Array[Array]) -> Array:
	if piece.id == 0: return []

	var kickTable
	if piece.id <= 5:
		kickTable = KICK_TABLE_JLSTZ[piece.state]
	else:
		kickTable = KICK_TABLE_I[piece.state]
	for kick in kickTable:
		if can_rotate_right(piece, matrix, kick[0], kick[1]):
			return kick

	return []

func test_kick_left(piece: Piece, matrix: Array[Array]) -> Array:
	if piece.id == 0: return []
	
	var kickTable
	if piece.id <= 5:
		kickTable = KICK_TABLE_JLSTZ[piece.state + 4]
	else:
		kickTable = KICK_TABLE_I[piece.state + 4]
	for kick in kickTable:
		if can_rotate_left(piece, matrix, kick[0], kick[1]):
			return kick

	return []

func test_kick_180(piece: Piece, matrix: Array[Array]) -> Array:
	if piece.id == 0: return []
	
	var kickTable
	if piece.id <= 5:
		kickTable = KICK_TABLE_JLSTZ[piece.state + 8]
	else:
		kickTable = KICK_TABLE_I[piece.state + 8]
	for kick in kickTable:
		if can_rotate_180(piece, matrix, kick[0], kick[1]):
			return kick

	return []

func rotate_right(piece: Piece, offsetX: int = 0, offsetY: int = 0) -> void:
	var shapes = PIECE_SHAPES[piece.id]
	var oldState = piece.state

	var baseX = piece.x[0] - shapes[oldState][0] + offsetX
	var baseY = piece.y[0] - shapes[oldState][4] - offsetY

	piece.state += 1
	if piece.state >= 4: piece.state = 0

	for i in range(4):
		piece.x[i] = shapes[piece.state][i] + baseX
		piece.y[i] = shapes[piece.state][i + 4] + baseY

func rotate_left(piece: Piece, offsetX: int = 0, offsetY: int = 0) -> void:
	var shapes = PIECE_SHAPES[piece.id]
	var oldState = piece.state

	var baseX = piece.x[0] - shapes[oldState][0] + offsetX
	var baseY = piece.y[0] - shapes[oldState][4] - offsetY

	piece.state -= 1
	if piece.state < 0: piece.state = 3

	for i in range(4):
		piece.x[i] = shapes[piece.state][i] + baseX
		piece.y[i] = shapes[piece.state][i + 4] + baseY

func rotate_180(piece: Piece, offsetX: int = 0, offsetY: int = 0) -> void:
	var shapes = PIECE_SHAPES[piece.id]
	var oldState = piece.state

	var baseX = piece.x[0] - shapes[oldState][0] + offsetX
	var baseY = piece.y[0] - shapes[oldState][4] - offsetY

	piece.state = (piece.state + 2) % 4

	for i in range(4):
		piece.x[i] = shapes[piece.state][i] + baseX
		piece.y[i] = shapes[piece.state][i + 4] + baseY

func test_tspin_not_move(piece: Piece, matrix: Array[Array]) -> bool:
	# 检查上方角
	var blocked = true
	for i in range(4):
		if piece.y[i] <= 0:
			continue
		if matrix[piece.y[i] - 1][piece.x[i]] >= 0:
			blocked = false
			break
	if blocked:
		return false
	# 检查下方是否被阻挡
	blocked = true
	for i in range(4):
		if piece.y[i] < -1:
			continue
		if piece.y[i] >= 27:
			blocked = false
			break
		if matrix[piece.y[i] + 1][piece.x[i]] >= 0:
			blocked = false
			break
	if blocked:
		return false
	# 检查左方是否被阻挡
	blocked = true
	for i in range(4):
		if piece.y[i] < 0:
			continue
		if piece.x[i] == 0:
			blocked = false
			break
		if matrix[piece.y[i]][piece.x[i] - 1] >= 0:
			blocked = false
			break
	if blocked:
		return false
	# 检查右方是否被阻挡
	blocked = true
	for i in range(4):
		if piece.y[i] < 0:
			continue
		if piece.x[i] == 9:
			blocked = false
			break
		if matrix[piece.y[i]][piece.x[i] + 1] >= 0:
			blocked = false
			break

	return not blocked
