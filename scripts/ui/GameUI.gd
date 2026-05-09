# scripts/ui/GameUI.gd
extends Control
class_name GameUI

## 需要一个 BoardLogic 引用
@export var board_logic: BoardLogic = null

## UI 元素
@onready var score_container: HBoxContainer = %ScoreContainer
@onready var lines_container: HBoxContainer = %LinesContainer
@onready var label_mode: Label = %LabelMode
@onready var label_score_value: Label = %LabelScoreValue
@onready var label_lines_value: Label = %LabelLinesValue
@onready var label_time_value: Label = %LabelTimeValue
@onready var label_pps_value: Label = %LabelPPSValue

var elapsed_time: float = 0.0
var run_flag: bool = false
var display_score: int = 0
var real_score: int = 0

func _ready():
	score_container.visible = Global.selected_mode <= 0
	lines_container.visible = Global.selected_mode > 0
	label_mode.text = Global.get_mode_name()
	if board_logic:
		board_logic.score_changed.connect(_on_score_changed)
		board_logic.lines_changed.connect(_on_line_changed)

func reset():
	elapsed_time = 0.0
	run_flag = false
	display_score = 0
	real_score = 0
	label_score_value.text = "0"
	label_lines_value.text = "0/40"
	label_time_value.text = "0'00.00"
	label_pps_value.text = "0.00"

func start():
	run_flag = true

func stop():
	run_flag = false

func update_time(time_sec: float) -> void:
	elapsed_time = time_sec
	_update_time_pps(elapsed_time)

func _process(delta: float):
	if not run_flag:
		return
	elapsed_time += delta
	if display_score < real_score:
		display_score += 1
		label_score_value.text = str(display_score)
	_update_time_pps(elapsed_time)

func _update_time_pps(time_sec: float) -> void:
	var minutes = floori(time_sec / 60)
	var seconds = floori(time_sec) % 60
	var frame = floori(time_sec * 100) % 60
	label_time_value.text = "%d'%02d.%02d" % [minutes, seconds, frame]
	
	var cur_pps = "%.2f" % (board_logic.piece_count / time_sec) if time_sec > 0 else "0.00"
	label_pps_value.text = cur_pps

func _on_score_changed(score: int) -> void:
	real_score = score

func _on_line_changed(line: int) -> void:
	label_lines_value.text = "%d/40" % line
