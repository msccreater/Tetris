# scripts/replay/ReplayAnalyzer.gd
class_name ReplayAnalyzer
extends Control

@export var replay_player: ReplayPlayer = null
#@export var board_logic: BoardLogic = null

@onready var panel: Panel = %Panel
@onready var label_step: Label = %LabelStep
@onready var slider: HSlider = %HSlider
@onready var btn_prev: Button = %BtnPrev
@onready var btn_next: Button = %BtnNext
@onready var btn_play: Button = %BtnPlay
@onready var btn_pause: Button = %BtnPause
@onready var label_status: Label = %LabelStatus
@onready var btn_speed_up: Button = %BtnSpeedUp
@onready var btn_speed_down: Button = %BtnSpeedDown
@onready var label_speed: Label = %LabelSpeed
@onready var item_list: ItemList = %ItemList

var _actions: Array = []
var _current_step: int = -1

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	btn_prev.pressed.connect(_on_prev)
	btn_next.pressed.connect(_on_next)
	btn_play.pressed.connect(_on_play)
	btn_pause.pressed.connect(_on_pause)
	btn_speed_up.pressed.connect(_on_speed_up)
	btn_speed_down.pressed.connect(_on_speed_down)
	slider.value_changed.connect(_on_slider_changed)
	item_list.item_selected.connect(_on_item_selected)
	if replay_player:
		replay_player.replay_finished.connect(_on_replay_finished)
	update_status_label(false)
	update_speed_label()

func _input(event: InputEvent) -> void:
	if not Global.play_replay:
		return
	if event.is_action_pressed("analyzer_tongle"):
		if visible:
			hide_panel()
		else:
			show_panel()
	if event.is_action_pressed("analyzer_prev"):
		_on_prev()
	if event.is_action_pressed("analyzer_next"):
		_on_next()
	if event.is_action_released("analyzer_play_pause"):
		if replay_player:
			if replay_player._is_playing:
				_on_pause()
			else:
				_on_play()
	if event.is_action_released("analyzer_speed_up"):
		_on_speed_up()
	if event.is_action_released("analyzer_speed_down"):
		_on_speed_down()

func _process(_delta: float) -> void:
	if not visible or not replay_player or not replay_player._is_playing:
		return
	# 自动播放状态（非逐帧）
	if replay_player._is_playing:
		var idx = replay_player._current_index
		if idx != _current_step:
			_current_step = idx
			update_current_step()

func set_actions(actions: Array):
	_actions = actions
	_current_step = -1
	slider.max_value = max(0, actions.size() - 1)
	slider.set_value_no_signal(0)
	item_list.clear()
	for i in range(actions.size()):
		var act = actions[i]
		var op_name = Global.CODE_TO_ACTION.get(int(act.get(1)), "?")
		var time = act.get(0)
		item_list.add_item("%3d: [%.2f] %s" % [i+1, time, op_name])

func _jump_to_step(target: int) -> void:
	if target < 0 or target >= _actions.size():
		return

	# 重载回放数据并执行到目标步
	if replay_player and _actions.size() > 0:
		var target_time = 0.0
		if target > 0:
			target_time = _actions[target-1][0]
		replay_player.seek(target_time)
		_current_step = target
		update_status_label(false)
		update_current_step()

func update_current_step():
	if _actions.is_empty(): return
	var idx = clamp(_current_step, 0, _actions.size() - 1)
	var act = _actions[idx]
	var op_name = Global.CODE_TO_ACTION.get(int(act.get(1)), "?")
	label_step.text = "Step %d/%d: [%.2f] %s" % [idx+1, _actions.size(), act.get(0), op_name]
	slider.set_value_no_signal(idx)
	item_list.select(idx)
	item_list.ensure_current_is_visible()

func _on_prev():
	if _current_step > 0:
		_current_step -= 1
		_jump_to_step(_current_step)

func _on_next():
	if _current_step < _actions.size() - 1:
		_current_step += 1
		_jump_to_step(_current_step)

func _on_item_selected(index: int):
	_jump_to_step(index)

func _on_slider_changed(value: float):
	var new_step = int(value)
	if new_step != _current_step:
		_jump_to_step(new_step)

func _on_play():
	if replay_player:
		replay_player._is_playing = true
		update_status_label(true)

func _on_pause():
	if replay_player:
		replay_player._is_playing = false
		update_status_label(false)
		update_current_step()

func _on_speed_up():
	if replay_player:
		replay_player.speed_up()
		update_speed_label()

func _on_speed_down():
	if replay_player:
		replay_player.speed_down()
		update_speed_label()

func _on_replay_finished() -> void:
	update_status_label(false)
	_current_step = replay_player._actions.size()
	update_current_step()

func update_status_label(is_playing: bool) -> void:
	if not label_status:
		return
	var style := label_status.get_theme_stylebox("normal") as StyleBoxFlat
	if is_playing:
		label_status.text = "播放中"
		label_status.add_theme_color_override("font_color", Color("#66ff66"))
		style.bg_color = Color("#1e5227")
		label_status.add_theme_stylebox_override("normal", style)
	else:
		# 判断是否已结束（可借助 replay_player._actions 与当前 index 比较）
		if replay_player and replay_player._current_index >= replay_player._actions.size() and not replay_player._is_playing:
			label_status.text = "已结束"
			label_status.add_theme_color_override("font_color", Color("#ff6666"))
			style.bg_color = Color("#4d2327")
			label_status.add_theme_stylebox_override("normal", style)
		else:
			label_status.text = "已暂停"
			label_status.add_theme_color_override("font_color", Color("#ff6666"))
			style.bg_color = Color("#4d2327")
			label_status.add_theme_stylebox_override("normal", style)

func update_speed_label():
	if replay_player:
		label_speed.text = "%.1fx" % replay_player.get_speed()

func show_panel():
	visible = true
	var tween = create_tween()
	tween.tween_property(panel, "position:x", 0, 0.2).from(300)
	if replay_player:
		var idx = replay_player._current_index
		if idx != _current_step:
			_current_step = idx
			update_current_step()
		_on_pause()

func hide_panel():
	var tween = create_tween()
	tween.tween_property(panel, "position:x", 300, 0.2).from(0)
	tween.tween_callback(
		func():
			visible = false
			_on_play()
	)
