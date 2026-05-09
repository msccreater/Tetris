class_name BoardRenderer
extends Node2D

## 需要外部设置
@export var board_logic: BoardLogic = null
@export var block_texture: Texture2D = null
@export var next_texture: Texture2D = null
@export var mid_texture: Texture2D = null

const COLS := 10
const TOTAL_ROWS := 28
const VISIBLE_ROWS := 20
const HIDDEN_ROWS := 8
const VISIBLE_START_ROW := 8
const BOARD_X := 100
const NEXT_CELL_SIZE := 18
const TILE_H := 48

var CELL_SIZE := 30
var _hold_x := 20
var _next_x := 400
# 棋盘变换后的 Y 偏移（计算得到）
var _draw_offset_y: float = 0.0
# HOLD / NEXT 预览框的 Y 位置（与可见棋盘顶部对齐）
var _ui_y: float = 0.0

# 动画变量
var _shake_offset_y: float = 0.0
var _target_squeeze_x: float = 0.0
var _squeeze_offset_x: float = 0.0
var _squeeze_speed: float = 100.0   # 挤压响应速度

# 危险预警变量
var _visible_start_y: float = HIDDEN_ROWS * CELL_SIZE
var _target_visible_start_y: float = HIDDEN_ROWS * CELL_SIZE
var _danger_lerp_speed: float = 100.0

var _tween: Tween = null

func _ready() -> void:
	_calculate_cell_size()
	get_viewport().size_changed.connect(_calculate_cell_size)
	queue_redraw()

func _calculate_cell_size() -> void:
	var view_height = get_viewport().size.y
	CELL_SIZE = int(view_height / TOTAL_ROWS)
	_hold_x = BOARD_X - 4 * CELL_SIZE
	_next_x = BOARD_X + 10 * CELL_SIZE
	_visible_start_y = HIDDEN_ROWS * CELL_SIZE
	_target_visible_start_y = _visible_start_y
	_update_offsets()

func _update_offsets() -> void:
	var view_height = get_viewport().size.y
	var board_height = VISIBLE_ROWS * CELL_SIZE
	_draw_offset_y =  -HIDDEN_ROWS * CELL_SIZE + (view_height - board_height) / 2.0
	_ui_y = (view_height - board_height) / 2.0

func _process(delta: float) -> void:
	# 平滑挤压偏移
	_squeeze_offset_x = move_toward(_squeeze_offset_x, _target_squeeze_x, _squeeze_speed * delta)
	 # 危险偏移平滑
	_visible_start_y = move_toward(_visible_start_y, _target_visible_start_y, _danger_lerp_speed * delta)
	if abs(_visible_start_y - _target_visible_start_y) > 0.1 or abs(_squeeze_offset_x - _target_squeeze_x) > 0.1:
		queue_redraw()

func shake_hard_drop() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	var amplitude := 6.0
	_tween.tween_property(self, "_shake_offset_y", amplitude, 0.05)
	_tween.tween_property(self, "_shake_offset_y", -amplitude * 0.5, 0.08)
	_tween.tween_property(self, "_shake_offset_y", 0.0, 0.06)

# 设置挤压方向（-1左, 1右），对外接口
func set_squeeze(direction: int) -> void:
	_target_squeeze_x = 8.0 * direction   # 强度

# 释放挤压（恢复原位）
func release_squeeze() -> void:
	_target_squeeze_x = 0.0

func set_danger() -> void:
	_target_visible_start_y = (HIDDEN_ROWS  - 2) * CELL_SIZE

func reset_danger() -> void:
	_target_visible_start_y = HIDDEN_ROWS * CELL_SIZE

func cell_to_screen(col: int, row: int) -> Vector2:
	return Vector2(BOARD_X + col * CELL_SIZE + CELL_SIZE / 2.0,
				   _draw_offset_y + row * CELL_SIZE + CELL_SIZE / 2.0)

func _draw() -> void:
	if not board_logic:
		return
	# 棋盘区域（应用平移 + 动画偏移）
	draw_set_transform(Vector2(BOARD_X + _squeeze_offset_x, _draw_offset_y + _shake_offset_y))
	draw_board_background()
	draw_grid()
	draw_fixed_blocks()
	draw_ghost()
	draw_current_piece()
	draw_next_piece()
	draw_40_line()
	
	# UI 区域（重置变换，使用屏幕绝对坐标）
	draw_set_transform(Vector2())
	draw_hold_piece()
	draw_next_queue()
	draw_labels()

# =================== 棋盘背景与网格 ===================
func draw_board_background() -> void:
	var y_start = _visible_start_y
	var height = TOTAL_ROWS * CELL_SIZE - y_start
	if height <= 0: return
	var rect := Rect2(0, y_start, COLS * CELL_SIZE, height)
	draw_rect(rect, Color(0.06, 0.06, 0.1, 1.0), true)
	draw_rect(rect, Color(1.0, 1.0, 1.0, 0.27), false, 2.0)

func draw_grid() -> void:
	var grid_color := Color(1.0, 1.0, 1.0, 0.15)
	for x in range(COLS + 1):
		var from := Vector2(x * CELL_SIZE, _visible_start_y)
		var to := Vector2(x * CELL_SIZE, TOTAL_ROWS  * CELL_SIZE)
		draw_line(from, to, grid_color, 1.0)
	var start_row = int(ceil(_visible_start_y / CELL_SIZE))
	for y in range(start_row, TOTAL_ROWS + 1):
		var from := Vector2(0, y * CELL_SIZE)
		var to := Vector2(COLS * CELL_SIZE, y * CELL_SIZE)
		draw_line(from, to, grid_color, 1.0)

# =================== 方块绘制 ===================
func draw_fixed_blocks() -> void:
	for row in range(TOTAL_ROWS):
		for col in range(COLS):
			var type = board_logic.board[row][col]
			if type != -1:
				var pos := Vector2(col * CELL_SIZE, row * CELL_SIZE)
				draw_block(pos, type, {"texture":block_texture})

func draw_block(pos: Vector2, type: int, ext_info: Dictionary = {}) -> void:
	var alpha = ext_info.get("alpha", 1.0)
	var inset = ext_info.get("inset", 1)
	var cell_size = ext_info.get("cell_size", CELL_SIZE)
	if ext_info.has("texture"):
		var texture = ext_info.get("texture")
		var src_rect = Rect2(type * TILE_H, 0, TILE_H, TILE_H)
		var dst_rect = Rect2(pos, Vector2(cell_size, cell_size))
		var color = Color.WHITE
		color.a = alpha
		draw_texture_rect_region(texture, dst_rect, src_rect, color)
	else:
		var rect := Rect2(pos + Vector2(inset, inset), Vector2(cell_size - 2*inset, cell_size - 2*inset))
		var base_color := PieceData.COLORS[type]
		draw_rect(rect, base_color)
		draw_rect(rect, Color(0, 0, 0, 0.4), false, 1.0, true)

func draw_ghost() -> void:
	var piece := board_logic.ghost_piece
	if not piece or not piece.show: return
	for i in range(4):
		var pos := Vector2(piece.x[i] * CELL_SIZE, piece.y[i] * CELL_SIZE)
		draw_block(pos, piece.id, {"texture":block_texture, "alpha": 0.4})
	_draw_rotation_center(piece)

func draw_current_piece() -> void:
	var piece = board_logic.current_piece
	if not piece or not piece.show: return
	for i in range(4):
		var pos := Vector2(piece.x[i] * CELL_SIZE, piece.y[i] * CELL_SIZE)
		draw_block(pos, piece.id, {"texture":block_texture})
	_draw_rotation_center(piece)

func _draw_rotation_center(piece: Piece) -> void:
	var dx = 0
	var dy = 0
	if piece.id == 0:
		dx = piece.x[0] + 0.5
		dy = piece.y[0] + 0.5
	elif piece.id == 6:
		var offset_x = [0.5, -0.5, -0.5, 0.5, 0][piece.state]
		var offset_y = [0.5, 0.5, -0.5, -0.5, 0][piece.state]
		dx = piece.x[1] + offset_x
		dy = piece.y[1] + offset_y
	else:
		var idx = [0, 1, 1, 2, 2, 1, 0][piece.id]
		if idx > 0:
			dx = piece.x[idx]
			dy = piece.y[idx]
	var src_rect = Rect2(0, 0, TILE_H, TILE_H)
	var dst_rect = Rect2(dx * CELL_SIZE, dy * CELL_SIZE, CELL_SIZE, CELL_SIZE)
	draw_texture_rect_region(mid_texture, dst_rect, src_rect)

func draw_next_piece() -> void:
	var piece = board_logic.next_piece
	if not piece or not piece.show: return
	for i in range(4):
		var pos := Vector2(piece.x[i] * CELL_SIZE, piece.y[i] * CELL_SIZE)
		var src_rect = Rect2(0, 0, TILE_H, TILE_H)
		var dst_rect = Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE))
		var color = Color.WHITE
		draw_texture_rect_region(next_texture, dst_rect, src_rect, color)

func draw_40_line() -> void:
	if Global.selected_mode != Global.GameMode.DIG_40L:
		return
	if board_logic.lines_cleared_40L < 30:
		return
	var y = board_logic.lines_cleared_40L - 12
	var from := Vector2(0, y * CELL_SIZE)
	var to := Vector2(COLS * CELL_SIZE, y * CELL_SIZE)
	draw_dashed_line(from, to, Color.RED, 2.0)

# =================== HOLD / NEXT 预览 ===================
func draw_hold_piece() -> void:
	var origin := Vector2(_hold_x + _squeeze_offset_x, _ui_y + _shake_offset_y)
	var rect := Rect2(origin + Vector2(-1, 0), Vector2(4 * CELL_SIZE, 3 * NEXT_CELL_SIZE))
	draw_rect(rect, Color(1.0, 1.0, 1.0, 0.27), false, 2.0)
	var piece := board_logic.hold_id
	if piece == -1:
		return
	draw_piece_preview(piece, origin)

func draw_next_queue() -> void:
	var base_pos = Vector2(_next_x + _squeeze_offset_x, _ui_y + _shake_offset_y)
	var rect = Rect2(base_pos + Vector2(1,0),  Vector2(4 * CELL_SIZE, 3 * 5 * NEXT_CELL_SIZE))
	draw_rect(rect, Color(1.0, 1.0, 1.0, 0.27), false, 2.0)
	var queue := board_logic.next_queue
	for i in range(min(5, queue.size())):
		var piece: int = queue[i]
		var origin = base_pos + Vector2(0, i * 3 * NEXT_CELL_SIZE)
		draw_piece_preview(piece, origin)

func draw_piece_preview(piece: int, origin: Vector2) -> void:
	var width := PieceData.PIECE_WIDTHS[piece]
	var total_w := width * NEXT_CELL_SIZE
	var start_x := origin.x + (4 * CELL_SIZE - total_w) / 2.0
	var start_y = origin.y + (0.0 if piece == 6 else NEXT_CELL_SIZE/2.0)
	var shape = PieceData.PIECE_SHAPES[piece][0]
	for i in range(4):
		var dx :int = shape[i]
		var dy :int = shape[i + 4]
		var pos := Vector2(start_x + dx * NEXT_CELL_SIZE, start_y + dy * NEXT_CELL_SIZE)
		draw_block(pos, piece, {"texture":block_texture, "cell_size": NEXT_CELL_SIZE})

# =================== 标签 ===================
func draw_labels() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(_next_x + 20, _ui_y - 15), "NEXT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	draw_string(font, Vector2(_hold_x + 20, _ui_y - 15), "HOLD", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
