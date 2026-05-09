extends Node2D

class_name StarryEffect

class Star:
	var x: float
	var y: float
	var step: float
	
	func _init(screen_w: float, screen_h: float):
		x = randf() * screen_w
		y = randf() * screen_h
		# 原 JS: 0.1 * Math.random() + 0.2 = 0.2 ~ 0.3 像素/帧
		# 假设 60fps，每秒移动 12~18 像素
		step = (0.1 * randf() + 0.2) * 60.0  # 转换为 每秒像素
	
	func update(delta: float, screen_h: float):
		# 使用 delta 时间，确保不同帧率速度一致
		y += step * delta
		if y > screen_h:
			y = 0

var stars: Array[Star] = []
var screen_size: Vector2

@export var debug_mode: bool = false
var current_count: int = 64
const MAX_COUNT: int = 64
var is_fading_out: bool = false


var star_color: Color = Color("#afafaf")

func _ready():
	# 锁定 60fps，与 JS 的 requestAnimationFrame 一致
	Engine.max_fps = 60
	Engine.physics_ticks_per_second = 60
	
	screen_size = get_viewport_rect().size
	_init_stars()

func _init_stars():
	stars.clear()
	for i in range(MAX_COUNT):
		stars.append(Star.new(screen_size.x, screen_size.y))

func _process(delta):
	# 更新星星位置
	for i in range(mini(current_count, stars.size())):
		stars[i].update(delta, screen_size.y)
	
	# 动态调整数量
	if is_fading_out:
		if current_count > 0:
			current_count -= 1
	else:
		if current_count < MAX_COUNT:
			current_count += 1
	
	queue_redraw()

func _draw():
	# 绘制背景
	draw_rect(Rect2(0, 0, screen_size.x, screen_size.y), Color8(0, 17, 34, 255))
	
	# 绘制星星
	var draw_count: int = mini(current_count, stars.size())
	for i in range(draw_count):
		var star = stars[i]
		draw_rect(Rect2(star.x, star.y, 3, 3), star_color)
	
	# 绘制UI
	if debug_mode:
		_draw_ui()

func _draw_ui():
	var margin: float = 15.0
	var ui_x: float = margin
	var ui_y: float = margin
	
	draw_rect(Rect2(ui_x - 5, ui_y - 5, 250, 100), Color8(0, 0, 0, 150))
	
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 15), "🌟 星空效果", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(255, 255, 200, 255))
	
	var status_color = Color8(255, 255, 255, 220)
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 40), "星星: %d/64" % current_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, status_color)
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 60), "[S] 淡入/淡出  [R] 重置", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(200, 200, 200, 200))

func set_offset(fade_out: bool):
	is_fading_out = fade_out

func reset():
	current_count = MAX_COUNT
	is_fading_out = false
	_init_stars()

func _input(event):
	if not debug_mode: return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				is_fading_out = !is_fading_out
			KEY_R:
				reset()
