class_name SinglePlayer
extends Node2D

@onready var board_logic: BoardLogic = $BoardLogic
@onready var board_renderer: BoardRenderer = $BoardRenderer
@onready var particle_system: ParticleSystem = $ParticleSystem
@onready var note_system: NoteSystem = $NoteSystem
@onready var input_handler: InputHandler = $InputHandler
@onready var player: ReplayPlayer = $ReplayPlayer
@onready var game_ui: GameUI = %GameUI
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var game_over_ui: GameOverUI = %GameOverUI
@onready var replay_analyzer: ReplayAnalyzer = %ReplayAnalyzer
@onready var ready_ui: ReadyUI = %ReadyUI

@export var _debug_mode: bool = false

func _ready() -> void:
	ready_ui.ready_finish.connect(_on_ready_finish)
	board_logic.operation_performed.connect(_on_operation)
	board_logic.danger_changed.connect(_on_danger_changed)
	board_logic.game_end.connect(_on_game_end)
	board_logic.piece_droped.connect(_on_piece_droped)
	board_logic.lines_clear_tip.connect(_on_lines_clear_tip)
	game_over_ui.restart_pressed.connect(_restart)
	game_over_ui.back_to_menu_pressed.connect(_back_to_menu)
	if pause_menu:
		pause_menu.restart_pressed.connect(_restart)
		pause_menu.back_to_menu_pressed.connect(_back_to_menu)
	input_handler.refresh_settings()
	if Global.play_replay:
		start_video()
	else:
		start_game()

func _on_ready_finish():
	if Global.play_replay:
		player.start_replay()
	else:
		board_logic.start_first()
		game_ui.start()

func start_game():
	input_handler.input_enabled = true
	board_logic.reset()
	ready_ui.show_ready()
	game_ui.reset()
	board_renderer.reset_danger()
	Music.play_bgm()

func start_video():
	input_handler.input_enabled = false
	board_logic.reset(Global.replay_data.get("next"), Global.replay_data.get("garbage"))
	ready_ui.show_ready()
	game_ui.reset()
	board_renderer.reset_danger()
	player.load_replay(Global.replay_data)
	replay_analyzer.set_actions(Global.replay_data.get("action"))

func _process(delta: float) -> void:
	if Global.play_replay:
		board_renderer.queue_redraw()    # ★ 确保回放画面更新
		if player._is_playing:
			game_ui.update_time(player._play_time)
			board_logic.update_time(player._play_time)
		return

	board_logic.process_gravity(delta, input_handler.soft_drop_active)
	# 挤压效果控制
	if input_handler._left_held and not board_logic.can_move_left():
		board_renderer.set_squeeze(-1)
	elif input_handler._right_held and not board_logic.can_move_right():
		board_renderer.set_squeeze(1)
	else:
		board_renderer.release_squeeze()

	board_renderer.queue_redraw()

func _on_operation(op: StringName):
	if _debug_mode:
		var debug_str = "[%.2f] %s\n" % [board_logic.time_sec, op]
		debug_str += board_logic.dump_state() + "\n\n"
		print(debug_str)

func _on_danger_changed(is_danger: bool) -> void:
	if is_danger:
		board_renderer.set_danger()
	else:
		board_renderer.reset_danger()

func _on_game_end(won: bool, score: int, info_str: String, time_str: String) -> void:
	game_ui.stop()
	game_over_ui.show_game_over(won, score, info_str, time_str)

func _on_piece_droped(piece_data: Piece) -> void:
	board_renderer.shake_hard_drop()
	for i in range(4):
		var screen_pos = board_renderer.cell_to_screen(piece_data.x[i], piece_data.y[i])
		particle_system.emit_thrust(screen_pos + Vector2(randi_range(-10, 20), randi_range(-10, 10)-80))
		particle_system.emit_thrust(screen_pos + Vector2(randi_range(-10, 20), randi_range(-10, 10)-90))

func _on_lines_clear_tip(type: int, cnt: int, offset: Vector2) -> void:
	var show_pos = board_renderer.cell_to_screen(0, 15) + offset
	note_system.set_img_t(show_pos.x, show_pos.y, type, cnt)

func _restart():
	if Global.play_replay:
		start_video()
	else:
		start_game()

func _back_to_menu():
	Music.pause_bgm()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
