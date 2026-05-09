extends Control

const REPLAYS_DIR = "user://replays"

@onready var item_container: VBoxContainer = %ItemContainer
@onready var btn_back: Button = %BtnBack

const REPLAY_ITEM  = preload("res://scenes/ReplayListItem.tscn")
var replay_files: Array = []
var selected_item: ReplayListItem = null

func _ready() -> void:
	btn_back.pressed.connect(_on_back)
	refresh_list()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_back()

func refresh_list() -> void:
	# 清空旧列表
	for child in item_container.get_children():
		child.queue_free()
	replay_files.clear()
	
	var dir = DirAccess.open(REPLAYS_DIR)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".replay"):
			replay_files.append(file_name)
		file_name = dir.get_next()
	
	replay_files.sort_custom(func(a, b): return a > b)
	
	for f in replay_files:
		_create_item(f)

func _create_item(file_name: String) -> void:
	var item: ReplayListItem = REPLAY_ITEM.instantiate()
	item_container.add_child(item)
	item.set_file(file_name)
	item.play_pressed.connect(_on_play)
	item.delete_pressed.connect(_on_delete)
	item.item_selected.connect(_on_item_selected)   # 连接选中信号

func _on_item_selected(item: ReplayListItem) -> void:
	# 取消之前项的选中状态
	if selected_item and selected_item != item:
		selected_item.set_selected(false)
	# 设置新项为选中
	selected_item = item
	item.set_selected(true)

func _on_play(file_name: String) -> void:
	var path = REPLAYS_DIR.path_join(file_name)
	Global.load_log(path)
	Global.selected_mode = Global.replay_data.get("mode", Global.GameMode.TIME_SCORE)
	Global.play_replay = true
	get_tree().change_scene_to_file("res://scenes/SinglePlayer.tscn")

func _on_delete(file_name: String) -> void:
	var path = REPLAYS_DIR.path_join(file_name)
	DirAccess.remove_absolute(path)
	refresh_list()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
