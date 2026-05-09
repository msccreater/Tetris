# scripts/Global.gd (AutoLoad)
extends Node

var selected_mode: int = 0
var replay_data: Dictionary = {}
var play_replay: bool = false
var last_file_path: String = ""

enum GameMode {
	TIME_SCORE = -1,    # 限时打分
	ENDLESS = 0,        # 无尽模式
	RACE_40L = 1,       # 40行竞速
	DIG_40L = 2         # 40行挖掘
}

const MODE_NAMES: Dictionary = {
	GameMode.TIME_SCORE: "限时打分",
	GameMode.ENDLESS: "无尽模式",
	GameMode.RACE_40L: "40行竞速",
	GameMode.DIG_40L: "40行挖掘",
}

const ACTION_TO_CODE: Dictionary = {
	&"move_left": 1,
	&"move_right": 2,
	&"move_down": 4,
	&"rotate_cw": 5,
	&"hard_drop": 6,
	&"auto_down": 7,
	&"lock": 9,
	&"rotate_ccw": 10,
	&"rotate_180": 11,
	&"hold": 14,
	&"move_left_instant": 15,
	&"move_right_instant": 16,
	&"move_down_instant": 17,
}

const CODE_TO_ACTION: Dictionary = {
	1 : &"move_left",
	2 : &"move_right",
	4 : &"move_down",
	5 : &"rotate_cw",
	6 : &"hard_drop",
	7 : &"auto_down",
	9 : &"lock",
	10 : &"rotate_ccw",
	11 : &"rotate_180",
	14 : &"hold",
	15 : &"move_left_instant",
	16 : &"move_right_instant",
	17 : &"move_down_instant",
}
const SETTINGS_PATH = "user://settings.cfg"

# 默认设置
var settings: Dictionary = {
	"das_delay": 12.0,
	"arr_interval": 1.0,
	"down_das": 8.0,
	"down_arr": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"music_enabled": true,
	"sfx_enabled": true
}

func _ready() -> void:
	load_settings()

func get_mode_name() -> String:
	return MODE_NAMES[selected_mode]

func save_log(path: String, log_data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not log_data.has("mode"):
		log_data["mode"] = selected_mode
	file.store_string(JSON.stringify(log_data))
	file.close()

func load_log(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	replay_data = JSON.parse_string(file.get_as_text())
	_sanitize_data(replay_data)
	file.close()

func _sanitize_data(data: Dictionary):
	if data.has("next") and data["next"].size() > 0:
		for i in range(data["next"].size()):
			data["next"][i] = int(data["next"][i])
	if data.has("garbage") and data["garbage"].size() > 0:
		for i in range(data["garbage"].size()):
			data["garbage"][i] = int(data["garbage"][i])

func load_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		if data is Dictionary:
			settings.merge(data, true)   # 覆盖已存在的键
		file.close()

func save_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_var(settings)
	file.close()
