class_name InputHandler
extends Node

## 需要外部设置
@export var board_logic: BoardLogic = null

## DAS / ARR 参数（单位：秒，按 60fps 换算）
@export var das_delay: float = 12.0 / 60.0 # 左右移动 DAS 延迟 0.2s
@export var arr_interval: float = 1.0 / 60.0 # 左右移动 ARR 间隔 0.0167s
@export var down_das: float = 8.0 / 60.0 # 软降 DAS 延迟 0.133s
@export var down_arr: float = 1.0 / 60.0 # 软降 ARR 间隔

## 内部状态
var _left_das_timer := 0.0
var _left_arr_timer := 0.0
var _right_das_timer := 0.0
var _right_arr_timer := 0.0
var _down_das_timer := 0.0
var _down_arr_timer := 0.0

var _left_held := false
var _left_phase: int = 0 # 0=未按下, 1=DAS中, 2=arr重复中
var _right_held := false
var _right_phase: int = 0
var _down_held := false
var _down_phase: int = 0

## 输入锁定：当游戏结束或暂停时忽略输入
var input_enabled := true

var soft_drop_active: bool:
	get:
		return _down_held


func _process(delta: float) -> void:
	if not input_enabled or not board_logic or not board_logic.can_input():
		return

	# 处理左右移动 DAS/ARR
	if _left_held:
		match _left_phase:
			0:
				_left_phase = 1
				_left_das_timer = 0.0
			1:
				_left_das_timer += delta
				if _left_das_timer >= das_delay:
					if arr_interval == 0:
						board_logic.on_move_left(true)
						_left_phase = 0
					else:
						board_logic.on_move_left()
						_left_phase = 2
						_left_arr_timer = 0.0
			2:
				_left_arr_timer += delta
				while _left_arr_timer >= arr_interval:
					board_logic.on_move_left()
					_left_arr_timer -= arr_interval
	else:
		_left_phase = 0
		_left_das_timer = 0.0
		_left_arr_timer = 0.0

	if _right_held:
		match _right_phase:
			0:
				_right_phase = 1
				_right_das_timer = 0.0
			1:
				_right_das_timer += delta
				if _right_das_timer >= das_delay:
					if arr_interval == 0:
						board_logic.on_move_right(true)
						_right_phase = 0
					else:
						board_logic.on_move_right()
						_right_phase = 2
						_right_arr_timer = 0.0
			2:
				_right_arr_timer += delta
				while _right_arr_timer >= arr_interval:
					board_logic.on_move_right()
					_right_arr_timer -= arr_interval
	else:
		_right_phase = 0
		_right_das_timer = 0.0
		_right_arr_timer = 0.0

	# 软降 DAS/ARR
	if _down_held:
		match _down_phase:
			0:
				_down_phase = 1
				_down_das_timer = 0.0
			1:
				_down_das_timer += delta
				if _down_das_timer >= down_das:
					if down_arr == 0:
						board_logic.on_move_down(true)
						_down_phase = 0
					else:
						board_logic.on_move_down()
						_down_phase = 2
						_down_arr_timer = 0.0
			2:
				_down_arr_timer += delta
				while _down_arr_timer >= down_arr:
					board_logic.on_move_down()
					_down_arr_timer -= down_arr
	else:
		_down_phase = 0
		_down_das_timer = 0.0
		_down_arr_timer = 0.0


func _input(event: InputEvent) -> void:
	if not input_enabled or not board_logic or not board_logic.can_input():
		return
	
	# 左右移动
	if event.is_action_pressed("move_left"):
		board_logic.add_key_cnt()
		_left_held = true
		board_logic.on_move_left()
	elif event.is_action_released("move_left"):
		_left_held = false

	if event.is_action_pressed("move_right"):
		board_logic.add_key_cnt()
		_right_held = true
		board_logic.on_move_right()
	elif event.is_action_released("move_right"):
		_right_held = false

	# 软降
	if event.is_action_pressed("soft_drop"):
		board_logic.add_key_cnt()
		_down_held = true
		board_logic.on_move_down() # 第一格立即下落
	elif event.is_action_released("soft_drop"):
		_down_held = false

	# 硬降（单次）
	if event.is_action_pressed("hard_drop"):
		board_logic.add_key_cnt()
		board_logic.on_hard_drop()
	# 旋转
	if event.is_action_pressed("rotate_cw"):
		board_logic.add_key_cnt()
		board_logic.on_rotate_cw()
	if event.is_action_pressed("rotate_ccw"):
		board_logic.add_key_cnt()
		board_logic.on_rotate_ccw()
	if event.is_action_pressed("rotate_180"):
		board_logic.add_key_cnt()
		board_logic.on_rotate_180()
	# 暂存
	if event.is_action_pressed("hold"):
		board_logic.add_key_cnt()
		board_logic.on_hold()

func refresh_settings() -> void:
	das_delay = Global.settings.das_delay / 60.0
	arr_interval = Global.settings.arr_interval / 60.0
	down_das = Global.settings.down_das / 60.0
	down_arr = Global.settings.down_arr / 60.0
