# scripts/MainMenu.gd
extends Control

@onready var button_time_score: Button = %ButtonTimeScore
@onready var button_endless: Button = %ButtonEndless
@onready var button_40_lines: Button = %Button40Lines
@onready var button_40_dig: Button = %Button40Dig
@onready var button_replay: Button = %ButtonReplay
@onready var button_replay_list: Button = %ButtonReplayList
@onready var button_quit: Button = %ButtonQuit
@onready var button_settings: Button = %ButtonSettings
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	button_time_score.pressed.connect(_start.bind(Global.GameMode.TIME_SCORE))
	button_endless.pressed.connect(_start.bind(Global.GameMode.ENDLESS))
	button_40_lines.pressed.connect(_start.bind(Global.GameMode.RACE_40L))
	button_40_dig.pressed.connect(_start.bind(Global.GameMode.DIG_40L))
	button_replay.pressed.connect(_play_replay)
	button_replay_list.pressed.connect(_open_replay_list)
	button_settings.pressed.connect(_open_settings)
	button_quit.pressed.connect(_quit)
	animation_player.play("fade_in")

func _start(mode: int):
	# 切换到单人游戏场景，传递模式参数
	Global.selected_mode = mode
	Global.play_replay = false
	_change_to_main_scene()

func _play_replay():
	var file = FileAccess.open(Global.last_file_path, FileAccess.READ)
	if not file:
		print("没有回放文件")
		return
	Global.load_log(Global.last_file_path)
	Global.selected_mode = Global.replay_data.get("mode", Global.GameMode.TIME_SCORE)
	Global.play_replay = true
	_change_to_main_scene()

func _open_replay_list():
	get_tree().change_scene_to_file("res://scenes/ReplayList.tscn")

func _open_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/SettingsUI.tscn")

func _quit():
	get_tree().quit()

func _change_to_main_scene():
	get_tree().change_scene_to_file("res://scenes/SinglePlayer.tscn")
