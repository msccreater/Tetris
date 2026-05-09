extends Node2D

class_name HeartEffect

# 图片资源
@export var debug_mode: bool = false
@export var heart_texture: Texture2D

# 位置
var x: float
var y: float

# 速度
var spx: float
var spy: float

# 速度随机表 [0.1, 0.2, ..., 1.0]
var rnum: Array[float] = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

# 图片显示尺寸
const DRAW_WIDTH: float = 290.0
const DRAW_HEIGHT: float = 125.0
const OFFSET_X: float = 145.0  # DRAW_WIDTH / 2
const OFFSET_Y: float = 62.5   # DRAW_HEIGHT / 2 (原JS用64，接近一半)

var screen_size: Vector2

func _ready():
	Engine.max_fps = 60
	screen_size = get_viewport_rect().size
	
	# 加载默认图片
	if heart_texture == null:
		heart_texture = load("res://assets/images/mohu.png")
	
	# 初始化位置：屏幕中心
	x = screen_size.x / 2.0
	y = screen_size.y / 2.0
	
	# 随机初始速度
	spx = _random_speed()
	spy = _random_speed()

func _random_speed() -> float:
	# 从 rnum 数组随机选择
	var idx = randi() % rnum.size()
	return rnum[idx] * 60.0  # 转换为每秒像素

func _process(delta):
	_update(delta)
	queue_redraw()

func _update(delta: float):
	# 移动
	x += spx * delta
	y += spy * delta
	
	# X边界碰撞检测
	if x < 0 or x > screen_size.x:
		# 反转方向，随机新速度
		if spx > 0:
			spx = -_random_speed()
		else:
			spx = _random_speed()
		# 确保在边界内
		x = clamp(x, 0, screen_size.x)
	
	# Y边界碰撞检测
	if y < 0 or y > screen_size.y:
		# 反转方向，随机新速度
		if spy > 0:
			spy = -_random_speed()
		else:
			spy = _random_speed()
		# 确保在边界内
		y = clamp(y, 0, screen_size.y)

func _draw():
	# 绘制深色背景
	draw_rect(Rect2(0, 0, screen_size.x, screen_size.y), Color8(10, 20, 40, 255))
	
	# 绘制图片（以x,y为中心点）
	if heart_texture != null:
		# 原JS: drawImage(u, x - 145, y - 64, 290, 125)
		var draw_rect = Rect2(
			x - OFFSET_X,
			y - OFFSET_Y,
			DRAW_WIDTH,
			DRAW_HEIGHT
		)
		draw_texture_rect(heart_texture, draw_rect, false)
	else:
		# 如果没有图片，绘制一个红色爱心形状代替
		_draw_fallback_heart()
	
	# 绘制UI
	if debug_mode:
		_draw_ui()

func _draw_fallback_heart():
	# 简单的爱心形状（用两个圆形+三角形模拟）
	var heart_color = Color8(255, 100, 150, 200)
	var size = 60.0
	
	# 左半圆
	draw_circle(Vector2(x - size/3, y - size/6), size/3, heart_color)
	# 右半圆
	draw_circle(Vector2(x + size/3, y - size/6), size/3, heart_color)
	# 下三角形
	var points = PackedVector2Array([
		Vector2(x - size/2, y),
		Vector2(x + size/2, y),
		Vector2(x, y + size)
	])
	draw_polygon(points, PackedColorArray([heart_color]))

func _draw_ui():
	var margin: float = 15.0
	var ui_x: float = margin
	var ui_y: float = margin
	
	draw_rect(Rect2(ui_x - 5, ui_y - 5, 280, 90), Color8(0, 0, 0, 150))
	
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 15), "💕 爱心/模糊效果", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(255, 150, 200, 255))
	
	var status_color = Color8(255, 255, 255, 220)
	var texture_status = "已加载" if heart_texture != null else "未找到图片"
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 40), "图片: %s" % texture_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, status_color)
	
	# 显示当前速度
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 65), "速度: (%.1f, %.1f)  [R] 重置" % [spx/60.0, spy/60.0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(200, 200, 200, 200))

# set_offset (原JS有此方法但为空实现)
func set_offset(offset: float):
	# 原JS中 set_offset 为空函数，不做任何操作
	pass

func reset():
	x = screen_size.x / 2.0
	y = screen_size.y / 2.0
	spx = _random_speed()
	spy = _random_speed()

func _input(event):
	if not debug_mode: return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				reset()
