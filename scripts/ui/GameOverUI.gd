# scripts/ui/GameOverUI.gd
extends Control

class_name GameOverUI

signal restart_pressed
signal back_to_menu_pressed

@onready var panel: Panel = $Panel
@onready var label_result: Label = $Panel/VBoxContainer/LabelResult
@onready var label_score: Label = $Panel/VBoxContainer/LabelScore
@onready var label_info: Label = $Panel/VBoxContainer/LabelInfo
@onready var label_time: Label = $Panel/VBoxContainer/LabelTime
@onready var btn_restart: Button = $Panel/VBoxContainer/HBoxContainer/BtnRestart
@onready var btn_menu: Button = $Panel/VBoxContainer/HBoxContainer/BtnMenu
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready():
	visible = false
	btn_restart.pressed.connect(_on_restart)
	btn_menu.pressed.connect(_on_menu)


func show_game_over(won: bool, score: int, info_str: String, time_str: String):
	visible = true
	if won:
		label_result.text = "YOU WIN!"
		label_result.add_theme_color_override("font_color", Color("#00ff88"))
	else:
		label_result.text = "GAME OVER"
		label_result.add_theme_color_override("font_color", Color("#ff4466"))
	label_score.text = "Score: %d" % score
	label_info.text = info_str
	label_time.text = "Time: %s" % time_str
	animation_player.play("popup")


func close_game_over():
	visible = false


func _on_restart():
	visible = false
	restart_pressed.emit()


func _on_menu():
	visible = false
	back_to_menu_pressed.emit()
