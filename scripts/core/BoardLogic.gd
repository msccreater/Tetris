class_name BoardLogic
extends Node

## 信号
signal game_end(is_win: bool, score: int, info_str: String, time_str: String)
signal danger_changed(is_danger: bool)
signal score_changed(score: int)
signal lines_changed(lines: int)
signal operation_performed(operation: StringName)
signal piece_droped(piece_data: Piece)
signal lines_clear_tip(type: int, cnt: int, offset: Vector2)

## 常量
const COLS := 10
const ROWS := 28          # 含隐藏区 8 行
const VISIBLE_ROWS := 20  # 可见行数 8-27
const SPAWN_X := 3        # 新生方块列偏移
const SPAWN_Y := 3        # 新生方块行（隐藏区上方）

## 游戏参数
var fall_delay: float = 1.0 # 正常下落间隔（秒）
var fall_timer := 0.0 # 下落计时器
var move_delay_count: int = 10 # 移动延迟锁定次数
var rotate_delay_count: int = 10 # 旋转延迟锁定次数
var min_fall_delay: float = 0.12     # 最小间隔，近似 7/60 秒
var speedup_interval: float = 16.0   # 每 16 秒加速一次
var speedup_step: float = 0.0167     # 每次加速减少的秒数 (≈1/60)


#游戏数据
var cell_count: int = 0
var piece_count: int = 0
var lines_cleared_40L: int = 0
var combo_count: int = -1
var b2b_count: int = -1
var score: int = 0
var key_count: int = 0
var hold_id: int = -1
var time_sec: float = 0.0
var last_speedup_time: float = 0.0
var start_time_str: String = ""
var game_over: int = -1 #(-1:没结束, 0:失败 1:胜利)
var ready_stage: bool = true
var can_hold: bool = false
var t_spin: bool = false
var danger_falg: bool = false
var suppress_op_signal: bool = false
var garbage_data: Array = []
#棋盘数据
var board: Array[Array] = [] #存piece_id
var current_piece: Piece = Piece.new() #当前方块
var ghost_piece: Piece = Piece.new() #幽灵方块
var next_piece: Piece = Piece.new() #下一个块
var next_queue: Array = []   #5个预览方块ID
var bag_gen: BagGenerator = BagGenerator.new()
var xrs: XRS = XRS.new() #旋转系统
var m_log: Log = Log.new()

func dump_state() -> String:
	var cur = "%d rot:%d at (%d,%d)" % [current_piece.id, current_piece.state, current_piece.x[0], current_piece.y[0]]
	var nexts = []
	for i in next_queue.size():
		nexts.append(str(next_queue[i]))
	var hold_str = str(hold_id) if hold_id != -1 else "empty"
	var board_str = ""
	for y in range(8, ROWS):
		for x in range(COLS):
			var v = board[y][x]
			board_str += str(v) if v != -1 else "."
		board_str += "\n"
	return "--- STATE ---\nCurrent: %s\nHold: %s\nNext: %s\nBoard:\n%s" % [cur, hold_str, ", ".join(nexts), board_str]

func _emit_op(op: StringName) -> void:
	if not suppress_op_signal:
		operation_performed.emit(op)
		m_log.log_action(time_sec, op)

func reset(init_next: Array = [], init_garbage: Array = []) -> void:
	cell_count = 0
	piece_count = 0
	lines_cleared_40L = 0
	combo_count = -1
	b2b_count = -1
	score = 0
	key_count = 0
	hold_id = -1
	time_sec = 0
	last_speedup_time = 0.0
	start_time_str = Time.get_datetime_string_from_system()
	game_over = -1
	ready_stage = true
	can_hold = true
	t_spin = false
	danger_falg = false
	suppress_op_signal = false
	garbage_data = init_garbage
	m_log.clear()
	_init_board()
	if Global.selected_mode == Global.GameMode.DIG_40L:
		_init_garbage()
		cell_count = 90
	current_piece.show = false
	ghost_piece.show = false
	next_piece.show = false
	next_queue.clear()
	_init_next_queue(init_next)

func start_first():
	ready_stage = false
	spawn_piece(true)
	ghost_piece.show = true
	next_piece.show = true

func can_input() -> bool:
	if ready_stage or game_over != -1:
		return false
	return true

func update_time(time: float) -> void:
	if not Global.play_replay: return
	time_sec = time

func _init_board() -> void:
	board.clear()
	for row in ROWS:
		var row_data: Array[int] = []
		row_data.resize(COLS)
		row_data.fill(-1)
		board.append(row_data)

func _init_garbage() -> void:
	for row in range(18, ROWS):
		var hole = randi() % COLS
		if not garbage_data.is_empty():
			hole = garbage_data.pop_front()
		m_log.log_garbage(hole)
		for col in range(COLS):
			board[row][col] = 7 if col != hole else -1

func _init_next_queue(init_next: Array = []) -> void:
	if not init_next.is_empty():
		next_queue = init_next.duplicate()
	else:
		while next_queue.size() < 5:
			var new_type = bag_gen.get_next()
			next_queue.append(new_type)
			m_log.log_next(new_type)

#生成、暂存与幽灵块
func spawn_piece(reset_can_hold:bool = false) -> void:
	if reset_can_hold:
		can_hold = true
	var type :int = next_queue.pop_front()
	var new_type = bag_gen.get_next()
	next_queue.append(new_type)
	m_log.log_next(new_type)
	current_piece.id = type
	current_piece.show = true
	xrs.init_shape(current_piece)
	next_piece.id = next_queue.front()
	xrs.init_shape(next_piece)
	_update_ghost()
	fall_timer = 0

func _update_ghost() -> void:
	ghost_piece.id = current_piece.id
	ghost_piece.state = current_piece.state
	ghost_piece.show = true
	for i in range(4):
		ghost_piece.x[i] = current_piece.x[i]
		ghost_piece.y[i] = current_piece.y[i]
	for r in range(26):
		for i in range(4):
			if ghost_piece.y[i] + 1 >= 0:
				if ghost_piece.y[i] >= 27: return
				if board[ghost_piece.y[i] + 1][ghost_piece.x[i]] >= 0: return
		for i in range(4):
			ghost_piece.y[i] += 1

func _check_over() -> void:
	if game_over != -1: return
	var is_fail = false
	for i in range(4):
		var dx = current_piece.x[i]
		var dy = current_piece.y[i]
		if board[dy][dx] >= 0:
			is_fail = true
			break
	if not is_fail:
		var cur_danger = false
		for i in range(3, 7):
			if board[10][i] >= 0:
				cur_danger = true
				break
		if cur_danger != danger_falg:
			danger_falg = cur_danger
			danger_changed.emit(danger_falg)
	else:
		_game_over(false)

func _game_over(is_win: bool) -> void:
	if is_win:
		Music.play_win()
	else:
		Music.play_over()
	game_over = 1 if is_win else 0
	var kpp_str = "kpp: %.2f" % (key_count / piece_count)
	var minutes = floori(time_sec / 60)
	var seconds = floori(time_sec) % 60
	var frame = floori(time_sec * 100) % 60
	var time_str = "%d'%02d.%02d" % [minutes, seconds, frame]
	game_end.emit(is_win, score, kpp_str, time_str)
	if not Global.play_replay:
		DirAccess.make_dir_recursive_absolute("user://replays")
		var datetime_str = "%s_%s" % [start_time_str.replace(":", "-").replace("T", "_"),  time_str]
		var mode_name = Global.get_mode_name()
		var file_path = "user://replays/%s_%s.replay" % [datetime_str, mode_name]
		Global.last_file_path = file_path
		m_log.save_log(file_path)

#移动与旋转
func add_key_cnt() -> void:
	key_count += 1

func can_move_left() -> bool:
	for i in range(4):
		if current_piece.x[i] <= 0: return false
		if current_piece.y[i] >= 0 and board[current_piece.y[i]][current_piece.x[i]-1] >= 0:
			return false
	return true

func can_move_right() -> bool:
	for i in range(4):
		if current_piece.x[i] + 1 >= COLS: return false
		if current_piece.y[i] >= 0 and board[current_piece.y[i]][current_piece.x[i]+1] >= 0:
			return false
	return true

func can_move_down() -> bool:
	for i in range(4):
		if current_piece.y[i] + 1 < 0:
			continue
		if current_piece.y[i] + 1 >= ROWS: return false
		if board[current_piece.y[i]+1][current_piece.x[i]] >= 0:
			return false
	return true

func move_left():
	for i in range(4):
		current_piece.x[i] -= 1

func on_move_left(instant: bool = false) -> void:
	if instant:
		var success = false
		while can_move_left():
			success = true
			move_left()
		if success:
			_update_ghost()
			_emit_op(&"move_left_instant")
	else:
		if can_move_left():
			move_left()
			_update_ghost()
			move_delay_count -= 1
			if move_delay_count > 0:
				fall_timer = 0
			_emit_op(&"move_left")
			Music.play_move()

func move_right():
	for i in range(4):
		current_piece.x[i] += 1

func on_move_right(instant: bool = false) -> void:
	if instant:
		var success = false
		while can_move_right():
			success = true
			move_right()
		if success:
			_update_ghost()
			_emit_op(&"move_right_instant")
	else:
		if can_move_right():
			move_right()
			_update_ghost()
			move_delay_count -= 1
			if move_delay_count > 0:
				fall_timer = 0
			_emit_op(&"move_right")
			Music.play_move()

func on_move_down(instant: bool = false) -> void:
	if instant:
		var success = false
		while can_move_down():
			success = true
			move_down()
		if success:
			fall_timer = 0
			_emit_op(&"move_down_instant")
	else:
		if can_move_down():
			move_down()
			fall_timer = 0
			_emit_op(&"move_down")
			Music.play_move()

func move_down() -> void:
	for i in range(4):
		current_piece.y[i] += 1

# 1: CW右旋, -1: CCW左旋, 2: 180旋转
func _rotate_xrs(direction: int) -> bool:
	var success = false
	if direction == 1:
		# 右旋
		if xrs.can_rotate_right(current_piece, board):
			rotate_delay_count -= 1
			if rotate_delay_count > 0:
				fall_timer = 0
			xrs.rotate_right(current_piece)
			_update_ghost()
			success = true
		else:
			var kick = xrs.test_kick_right(current_piece, board)
			if kick.size() == 2:
				xrs.rotate_right(current_piece, kick[0], kick[1])
				_update_ghost()
				success = true
	elif direction == -1:
		# 左旋
		if xrs.can_rotate_left(current_piece, board):
			rotate_delay_count -= 1
			if rotate_delay_count > 0:
				fall_timer = 0
			xrs.rotate_left(current_piece)
			_update_ghost()
			success = true
		else:
			var kick = xrs.test_kick_left(current_piece, board)
			if kick.size() == 2:
				xrs.rotate_left(current_piece, kick[0], kick[1])
				_update_ghost()
				success = true
	elif direction == 2:
		if xrs.can_rotate_180(current_piece, board):
			xrs.rotate_180(current_piece)
			_update_ghost()
			success = true
		else:
			var kick = xrs.test_kick_180(current_piece, board)
			if kick.size() == 2:
				xrs.rotate_180(current_piece, kick[0], kick[1])
				_update_ghost()
				success = true
	if success and current_piece.id == 5:
		t_spin = xrs.test_tspin_not_move(current_piece, board)
	return success

func on_rotate_cw() -> void:
	if _rotate_xrs(1):
		_emit_op(&"rotate_cw")
		Music.play_rotate()

func on_rotate_ccw() -> void:
	if _rotate_xrs(-1):
		_emit_op(&"rotate_ccw")
		Music.play_rotate()

func on_rotate_180() -> void:
	if _rotate_xrs(2):
		_emit_op(&"rotate_180")

func on_hard_drop() -> void:
	while can_move_down():
		move_down()
	_emit_op(&"hard_drop")
	Music.play_space()
	piece_droped.emit(current_piece)
	suppress_op_signal = true
	lock()
	suppress_op_signal = false
	_check_over()

func on_hold() -> void:
	if not can_hold: return
	suppress_op_signal = true
	can_hold = false
	if hold_id == -1:
		hold_id = current_piece.id
		spawn_piece(true)
	else:
		var tmp_id = hold_id
		hold_id = current_piece.id
		current_piece.id = tmp_id
		xrs.init_shape(current_piece)
		_update_ghost()
	suppress_op_signal = false
	_emit_op(&"hold")

func _check_clear() -> Array:
	var rows = current_piece.y.duplicate()
	rows.sort()
	var last_row = -1
	var clear_line = 0
	var dig_line = 0
	for i in range(4):
		var row = rows[i]
		if row < 0 or row == last_row: continue
		last_row = row
		
		var is_full = true
		for c in range(COLS):
			if board[row][c] < 0:
				is_full = false
				break
		
		if is_full:
			clear_line += 1
			if Global.selected_mode == Global.GameMode.DIG_40L:
				if lines_cleared_40L <= 30:
					if last_row >= 18:
						dig_line += 1
				elif last_row >= lines_cleared_40L - 12:
					dig_line += 1
				for r in range(row, 1, -1):
					for c in range(COLS):
						board[r][c] = board[r-1][c]
			else:
				for r in range(row, 0, -1):
					for c in range(COLS):
						board[r][c] = board[r-1][c]
				if clear_line == 1:
					board[0].fill(-1)
	return [clear_line, dig_line]

func _get_score(lines_cleared: int) -> int:
	var line_scores = [0, 10, 30, 50, 70, 90, 110, 130]
	var result = 0
	if lines_cleared < line_scores.size():
		result = line_scores[lines_cleared]	
	return result

func _all_rise(lines: int) -> void:
	cell_count += 9 * lines
	for i in range(lines):
		var hole = randi_range(0, 9)
		if not garbage_data.is_empty():
			hole = garbage_data.pop_front()
		m_log.log_garbage(hole)
		board[0].fill(7)
		board[0][hole] = -1
		var row_data = board.pop_front()
		board.append(row_data)

func lock() -> void:
	current_piece.show = false
	for i in range(4):
		if current_piece.y[i] >= 0:
			board[current_piece.y[i]][current_piece.x[i]] = current_piece.id
	
	cell_count += 4
	piece_count += 1
	var clear_info = _check_clear()
	var clear_line = clear_info[0]
	var dig_line = clear_info[1]
	if clear_line > 0:
		combo_count += 1
		if combo_count > 0:
			lines_clear_tip.emit(9, combo_count, Vector2(-40, 20))
		cell_count -= 10 * clear_line
		if Global.selected_mode == Global.GameMode.RACE_40L:
			lines_cleared_40L += clear_line
		elif Global.selected_mode == Global.GameMode.DIG_40L:
			lines_cleared_40L += dig_line
		
		var music_id = 0
		if t_spin and current_piece.id == 5:
			lines_clear_tip.emit(clear_line + 3, 0, Vector2(-40, -20))
			t_spin = false
			score += _get_score(clear_line + 4)
			music_id = 5 + clear_line
			b2b_count += 1
			if b2b_count >= 1:
				score += 10 * b2b_count
				lines_clear_tip.emit(8, b2b_count, Vector2(80, -20))
		else:
			lines_clear_tip.emit(clear_line - 1, 0, Vector2(-40, -20))
			score += _get_score(clear_line)
			music_id = clear_line
			if clear_line > 3:
				b2b_count += 1
				if b2b_count >= 1:
					score += 10 * b2b_count
					lines_clear_tip.emit(8, b2b_count, Vector2(60, -20))
			else:
				b2b_count = -1
		
		if cell_count == 0:
			lines_clear_tip.emit(7, 0, Vector2.ZERO)
			music_id = 9
			score += 150
		
		Music.play_tspin(music_id)
		
		if Global.selected_mode == Global.GameMode.DIG_40L and dig_line > 0 and lines_cleared_40L - dig_line < 30:
			_all_rise(min(30 - (lines_cleared_40L - dig_line), dig_line))

		if Global.selected_mode == Global.GameMode.RACE_40L or Global.selected_mode == Global.GameMode.DIG_40L:
			lines_changed.emit(lines_cleared_40L)
			if lines_cleared_40L >= 40:
				_game_over(true)
				return
		else:
			score_changed.emit(score)
	else:
		combo_count = -1

	spawn_piece(true)

func _update_fall_speed():
	if Global.selected_mode != Global.GameMode.ENDLESS:
		return
	while time_sec - last_speedup_time >= speedup_interval:
		last_speedup_time += speedup_interval
		if fall_delay > min_fall_delay:
			fall_delay = max(fall_delay - speedup_step, min_fall_delay)

#重力、锁定与硬降
func process_gravity(delta: float, _is_soft_drop: bool) -> void:
	if Global.play_replay or ready_stage or game_over != -1:
		return
	time_sec += delta
	if Global.selected_mode == Global.GameMode.TIME_SCORE:
		if time_sec >= 120:
			_game_over(true)
			return

	_update_fall_speed()
	fall_timer += delta
	if fall_timer >= fall_delay:
		fall_timer -= fall_delay
		move_delay_count = 10
		rotate_delay_count = 10
		if not can_move_down():
			_emit_op(&"lock")
			lock()
			_check_over()
		else:
			move_down()
			_emit_op(&"auto_down")
