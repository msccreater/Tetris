class_name ReplayPlayer
extends Node

signal replay_finished

@export var board_logic: BoardLogic = null

var _actions: Array = []
var _play_time: float = 0.0
var _current_index: int = -1
var _is_playing: bool = false
var _play_speed: float = 1.0        # 播放速度倍率
var _current_replay_data: Dictionary = {}  # 缓存回放数据

func load_replay(data: Dictionary) -> void:
	_current_replay_data = data
	_actions = data["action"]

func start_replay():
	_current_index = 0
	_play_time = 0.0
	_is_playing = true
	board_logic.start_first()

func speed_up() -> void:
	_play_speed = min(_play_speed * 2.0, 16.0)

func speed_down() -> void:
	_play_speed = max(_play_speed / 2.0, 0.25)

func get_speed() -> float:
	return _play_speed

func stop() -> void:
	_is_playing = false

func seek(target_time: float) -> void:
	if _actions.is_empty():
		return
	_current_index = 0
	_is_playing = false
	board_logic.reset(_current_replay_data.get("next"), _current_replay_data.get("garbage"))
	board_logic.start_first()
	while _current_index < _actions.size() and _actions[_current_index][0] < target_time:
		var op_name = Global.CODE_TO_ACTION.get(int(_actions[_current_index].get(1)), "?")
		_execute_action(op_name)
		_current_index += 1
	_play_time = target_time

func _process(delta: float) -> void:
	if board_logic == null or not Global.play_replay or not _is_playing:
		return
	_play_time += delta * _play_speed
	# 执行所有时间点 <= 当前时间的操作
	var total_size = _actions.size()
	while _current_index < total_size and _actions[_current_index][0] < _play_time:
		var act = _actions[_current_index]
		var op_name = Global.CODE_TO_ACTION.get(int(act[1]))
		_execute_action(op_name)
		_current_index += 1
	# 播放完毕自动停止
	if _current_index >= _actions.size():
		_is_playing = false
		replay_finished.emit()

func _execute_action(action: StringName) -> void:
	match action:
		&"move_left": board_logic.on_move_left()
		&"move_right": board_logic.on_move_right()
		&"move_down": board_logic.on_move_down()
		&"auto_down": board_logic.move_down()
		&"hard_drop": board_logic.on_hard_drop()
		&"rotate_cw": board_logic.on_rotate_cw()
		&"rotate_ccw": board_logic.on_rotate_ccw()
		&"rotate_180": board_logic.on_rotate_180()
		&"hold": board_logic.on_hold()
		&"lock": board_logic.lock()
