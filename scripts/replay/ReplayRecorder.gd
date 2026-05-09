class_name Log
extends Node

var action_data: Array = []
var next_data: Array = []
var garbage_data: Array = []

func clear() -> void:
	action_data.clear()
	next_data.clear()
	garbage_data.clear()

func log_action(time: float, action: StringName) -> void:
	if Global.play_replay: return
	var code = Global.ACTION_TO_CODE.get(action, 0)
	var t = snapped(time, 0.01)
	action_data.append([t, code])

func log_next(piece_id: int) -> void:
	if Global.play_replay: return
	next_data.append(piece_id)

func log_garbage(hole_idx: int) -> void:
	if Global.play_replay: return
	garbage_data.append(hole_idx)

func save_log(save_path: String) -> void:
	var log_data = {
		"mode" = Global.selected_mode,
		"action" = action_data,
		"next" = next_data,
		"garbage" = garbage_data
	}
	Global.save_log(save_path, log_data)
