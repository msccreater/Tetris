# scripts/ui/PauseMenu.gd
extends Control
class_name PauseMenu

signal restart_pressed
signal back_to_menu_pressed

@onready var panel: Panel = $Panel
@onready var button_resume: Button = $Panel/VBoxContainer/ButtonResume
@onready var button_restart: Button = $Panel/VBoxContainer/ButtonRestart
@onready var button_menu: Button = $Panel/VBoxContainer/ButtonMenu
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	button_resume.pressed.connect(resume)
	button_restart.pressed.connect(_emit_restart)
	button_menu.pressed.connect(_emit_menu)

func _input(event):
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()

func pause():
	visible = true
	animation_player.stop()
	animation_player.play("popup")
	get_tree().paused = true

func resume():
	visible = false
	get_tree().paused = false

func _emit_restart():
	resume()
	restart_pressed.emit()

func _emit_menu():
	resume()
	back_to_menu_pressed.emit()
