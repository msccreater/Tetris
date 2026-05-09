extends HBoxContainer
class_name ReplayListItem

signal play_pressed(file_name: String)
signal delete_pressed(file_name: String)
signal item_selected(item: ReplayListItem)

@onready var label_name: Label = $LabelName
@onready var btn_play: Button = $BtnPlay
@onready var btn_delete: Button = $BtnDelete

var file_name: String = ""
var _selected: bool = false

func _ready() -> void:
	btn_play.pressed.connect(_on_play)
	btn_delete.pressed.connect(_on_delete)
	gui_input.connect(_on_gui_input)

func set_file(fname: String) -> void:
	file_name = fname
	label_name.text = fname

func set_selected(sel: bool) -> void:
	_selected = sel
	queue_redraw()

func _draw() -> void:
	if _selected:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.3, 0.5, 0.8))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.15, 0.15, 0.2, 0.6))

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 点击了行的空白区域（非按钮），发射选中信号
		item_selected.emit(self)
		#accept_event()   # 阻止事件继续传播

func _on_play() -> void:
	play_pressed.emit(file_name)

func _on_delete() -> void:
	delete_pressed.emit(file_name)
