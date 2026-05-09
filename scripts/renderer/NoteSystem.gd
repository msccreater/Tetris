class_name NoteSystem
extends Node2D

var _frame: int = 0
var _accumulated_time: float = 0.0
var _fixed_time_step: float = 1.0 / 60.0

var type_texture: Texture2D = preload("res://assets/images/type.png")
var num_texture: Texture2D = preload("res://assets/images/num.png")

var text_notes: Array[Dictionary] = []
var image_notes: Array[Dictionary] = []

var m_index: int = 0
var m_tindex: int = 0


func _ready() -> void:
	for i in range(5):
		text_notes.append(
			{
				"x": 0.0,
				"y": 0.0,
				"txt": "",
				"v": 1.0,
				"hide": true,
				"c": Color.WHITE,
			},
		)
	for i in range(5):
		image_notes.append(
			{
				"x": 0.0,
				"y": 0.0,
				"v": 1.0,
				"hide": true,
				"img": -1,
				"n": 0,
			},
		)


func _process(delta: float) -> void:
	_accumulated_time += delta
	while _accumulated_time >= _fixed_time_step:
		_frame += 1
		_update_animation()
		_accumulated_time -= _fixed_time_step


## 每逻辑帧调用一次，处理移动和淡出
func _update_animation() -> void:
	# 文本移动
	for note in text_notes:
		if not note.hide:
			note.y -= 1.0
	# 图片移动
	for img in image_notes:
		if not img.hide:
			img.y -= 1.0

	# 每 8 逻辑帧透明度衰减
	if _frame % 8 == 1:
		for note in text_notes:
			if not note.hide:
				note.v -= 0.1
				if note.v < 1e-4:
					note.hide = true
		for img in image_notes:
			if not img.hide:
				img.v -= 0.1
				if img.v < 0.001:
					img.hide = true

	# 动画更新后请求重绘
	queue_redraw()


func clear() -> void:
	for n in text_notes:
		n.hide = true
	for d in image_notes:
		d.hide = true


## 纯绘制
func _draw() -> void:
	_draw_text_notes()
	_draw_image_notes()


func _draw_text_notes() -> void:
	for note in text_notes:
		if not note.hide:
			var c = note.c
			c.a = note.v
			var x = note.x
			var y = note.y
			var font = ThemeDB.fallback_font
			var text_size = font.get_string_size(note.txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
			var draw_pos = Vector2(x - text_size.x / 2, y)
			draw_string(
				font,
				draw_pos,
				note.txt,
				HORIZONTAL_ALIGNMENT_CENTER,
				-1,
				24,
				c,
			)


func _draw_image_notes() -> void:
	for img in image_notes:
		if img.hide:
			continue
		var alpha = img.v
		var col = Color(1, 1, 1, alpha)
		var type_idx = img.img
		var num_val = img.n
		var x: float = img.x
		var y: float = img.y

		if type_idx < 11:
			draw_texture_rect_region(
				type_texture,
				Rect2(x, y, 168, 40),
				Rect2(0, 40 * type_idx, 168, 40),
				col,
			)
			if num_val > 0:
				var digits = _get_digits(num_val)
				if type_idx == 9:
					for i in digits.size():
						draw_texture_rect_region(
							num_texture,
							Rect2(x + 152 + 20 * i, y - 4, 20, 40),
							Rect2(20 * digits[i], 0, 20, 40),
							col,
						)
				elif type_idx == 8:
					for i in digits.size():
						draw_texture_rect_region(
							num_texture,
							Rect2(x + 132 + 20 * i, y - 4, 20, 40),
							Rect2(20 * digits[i], 0, 20, 40),
							col,
						)
		else:
			if num_val > 0:
				var digits = _get_digits(num_val)
				for i in digits.size():
					draw_texture_rect_region(
						num_texture,
						Rect2(x + 20 * i, y - 4, 20, 40),
						Rect2(20 * digits[i], 0, 20, 40),
						col,
					)


func _get_digits(num: int) -> Array[int]:
	var arr: Array[int] = []
	for ch in str(num):
		arr.append(int(ch))
	return arr


# ============================================================
# 便捷方法,外部调用
# ============================================================
# 居中文字提示
func set_note(txt: String, offset_x: float = 0.0, offset_y: float = 0.0, color: Color = Color.WHITE) -> void:
	m_tindex = (m_tindex + 1) % 5
	var note = text_notes[m_tindex]
	note.txt = txt
	note.x = get_viewport_rect().size.x / 2.0 + offset_x
	note.y = get_viewport_rect().size.y / 2.0 + offset_y
	note.v = 1.0
	note.c = color
	note.hide = false


# 绝对坐标文字提示
func set_note_ex(txt: String, x: float, y: float, color: Color = Color.WHITE) -> void:
	m_tindex = (m_tindex + 1) % 5
	var note = text_notes[m_tindex]
	note.txt = txt
	note.x = x
	note.y = y
	note.v = 1.0
	note.c = color
	note.hide = false


# 图片提示,消行,连击等
func set_img_t(x: float, y: float, img_type: int, num: int = 0) -> void:
	m_index = (m_index + 1) % 5
	var img = image_notes[m_index]
	img.x = x - 84
	img.y = y - 30
	img.v = 1.0
	img.hide = false
	img.img = img_type
	img.n = num
