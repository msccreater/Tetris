extends Control
class_name ReadyUI

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

signal ready_finish

var ready_second: int = 3:
	set(value):
		ready_second = value
		label.text = str(ready_second)

func _ready() -> void:
	visible = false
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	ready_second -= 1
	if ready_second <= 0:
		visible = false
		timer.stop()
		ready_finish.emit()

# 外部调用接口
func show_ready(sec: int = 3, pos: Vector2 = Vector2.ZERO):
	visible = true
	ready_second = sec
	if pos != Vector2.ZERO:
		position = pos
	timer.start()
