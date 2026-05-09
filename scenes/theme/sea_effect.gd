extends Node2D

class_name SeaEffect

class Squid:
	var color: Color
	var pos: Vector2
	var vel: Vector2
	var radius: float
	var trail: Array[Vector2]
	var phase: float
	var re: int
	var g: int
	var b: int
	
	func _init(screen_w: float, screen_h: float):
		re = int(20 + 160 * randf())
		g = int(20 + 160 * randf())
		b = int(20 + 160 * randf())
		color = Color8(re, g, b, 102)
		pos = Vector2(randf() * screen_w, randf() * screen_h)
		vel = Vector2((0.5 - randf()) / 4.0, 0.1 - randf())
		radius = 10 + 40 * randf()
		trail = []
		phase = randf() * 100.0

var squids: Array[Squid] = []
var time: float = 0.0
var screen_size: Vector2
var is_paused: bool = false
const TARGET_FPS: float = 60.0

# 背景设置
var bg_mode: int = 0
var grid_offset: float = 0.0

# UI字体
var ui_font: Font

@export var debug_mode: bool = false
@export var squid_count: int = 5:
	set(value):
		squid_count = max(0, value)
		_update_squid_count()

func _ready():
	Engine.max_fps = 60
	screen_size = get_viewport_rect().size
	_update_squid_count()
	
	# 获取系统字体
	ui_font = ThemeDB.fallback_font
	set_process(true)

func _update_squid_count():
	while squids.size() < squid_count:
		squids.append(Squid.new(screen_size.x, screen_size.y))
	while squids.size() > squid_count:
		squids.pop_back()

func _process(delta):
	if is_paused:
		return
	screen_size = get_viewport_rect().size
	time += delta * TARGET_FPS
	grid_offset += delta * 10
	queue_redraw()

func _input(event):
	if not debug_mode: return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				is_paused = !is_paused
			KEY_UP:
				squid_count += 1
			KEY_DOWN:
				squid_count = max(0, squid_count - 1)
			KEY_R:
				squids.clear()
				_update_squid_count()
			KEY_B:
				bg_mode = (bg_mode + 1) % 4

func _draw():
	_draw_background()
	
	for squid in squids:
		_update_squid(squid)
		_draw_squid(squid)
	
	# 绘制UI
	if debug_mode:
		_draw_ui()

func _draw_ui():
	var margin: float = 15.0
	var line_height: float = 20.0
	var ui_x: float = margin
	var ui_y: float = margin
	
	# 背景板
	var panel_width: float = 280.0
	var panel_height: float = 130.0
	draw_rect(Rect2(ui_x - 5, ui_y - 5, panel_width, panel_height), Color8(0, 0, 0, 150))
	
	# 标题
	draw_string(ui_font, Vector2(ui_x, ui_y + 15), "🦑 水母海洋效果", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(100, 200, 255, 255))
	
	# 状态信息
	var status_color = Color8(255, 255, 255, 220)
	var pause_status = "暂停中" if is_paused else "运行中"
	var pause_color = Color8(255, 100, 100, 255) if is_paused else Color8(100, 255, 100, 255)
	
	draw_string(ui_font, Vector2(ui_x, ui_y + 35), "数量: %d 只" % squid_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, status_color)
	draw_string(ui_font, Vector2(ui_x + 120, ui_y + 35), "[%s]" % pause_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, pause_color)
	
	# 操作提示
	var hint_y: float = ui_y + 60
	var hints = [
		"[↑/↓] 增加/减少水母",
		"[空格] 暂停/继续",
		"[B] 切换背景 (%d)" % bg_mode,
		"[R] 重置"
	]
	
	for hint in hints:
		draw_string(ui_font, Vector2(ui_x, hint_y), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(200, 200, 200, 200))
		hint_y += line_height

func _draw_background():
	match bg_mode:
		0:
			draw_rect(Rect2(0, 0, screen_size.x, screen_size.y), Color8(0, 17, 34, 77))
		1:
			_draw_gradient_background()
		2:
			_draw_grid_background()
		3:
			pass

func _draw_gradient_background():
	var steps = 20
	for i in range(steps):
		var t = float(i) / steps
		var alpha = lerp(0.2, 0.4, t)
		var color = Color8(0, int(10 + t * 20), int(30 + t * 30), int(alpha * 255))
		var y = screen_size.y * t
		draw_rect(Rect2(0, y, screen_size.x, screen_size.y / steps + 1), color)

func _draw_grid_background():
	draw_rect(Rect2(0, 0, screen_size.x, screen_size.y), Color8(0, 17, 34, 51))
	
	var grid_size: float = 50.0
	var line_color = Color8(255, 255, 255, 8)
	
	for x in range(0, int(screen_size.x) + grid_size, int(grid_size)):
		var offset_x = fmod(x + grid_offset, grid_size * 2) - grid_size
		draw_line(Vector2(offset_x, 0), Vector2(offset_x, screen_size.y), line_color, 1.0)
	
	for y in range(0, int(screen_size.y) + grid_size, int(grid_size)):
		draw_line(Vector2(0, y), Vector2(screen_size.x, y), line_color, 1.0)

func _update_squid(squid: Squid):
	var t = time
	var wave = sin((t + squid.phase) / 10.0)
	
	squid.pos.x += 4 * squid.vel.x
	squid.pos.y -= wave + 1.0
	squid.pos.y += squid.vel.y
	
	if squid.pos.x < -squid.radius:
		squid.pos.x = screen_size.x + squid.radius
	elif squid.pos.x > screen_size.x + squid.radius:
		squid.pos.x = -squid.radius
		
	if squid.pos.y < -squid.radius:
		squid.pos.y = screen_size.y + squid.radius
	elif squid.pos.y > screen_size.y + squid.radius:
		squid.pos.y = -squid.radius
	
	squid.trail.append(Vector2(squid.pos.x, squid.pos.y - 0.2 * squid.radius))
	var max_trail = int(3 * squid.radius)
	while squid.trail.size() > max_trail:
		squid.trail.remove_at(0)

func _draw_squid(squid: Squid):
	var t = time
	var wave = sin((t + squid.phase) / 10.0)
	
	var main_color = Color8(squid.re, squid.g, squid.b, 102)
	var trail_color = Color8(squid.re, squid.g, squid.b, 51)
	
	var start_angle = PI + (-0.5 + squid.vel.x) - wave / 4.0
	var end_angle = 0.5 + squid.vel.x + wave / 4.0
	
	_draw_jellyfish_head(squid.pos, squid.radius, start_angle, end_angle, main_color)
	_draw_tentacles(squid, trail_color)

func _draw_jellyfish_head(center: Vector2, r: float, start_angle: float, end_angle: float, color: Color):
	var points = PackedVector2Array()
	var segments = 32
	
	var angle_span: float
	if start_angle > end_angle:
		angle_span = (2 * PI - start_angle) + end_angle
	else:
		angle_span = end_angle - start_angle
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = start_angle + angle_span * t
		if angle > 2 * PI:
			angle -= 2 * PI
		var px = center.x + cos(angle) * r
		var py = center.y + sin(angle) * r
		points.append(Vector2(px, py))
	
	if points.size() > 0 and points[0] != points[points.size() - 1]:
		points.append(points[0])
	
	draw_polygon(points, PackedColorArray([color]))
	
	var edge_color = Color(color.r, color.g, color.b, min(1.0, color.a * 1.5))
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], edge_color, 1.0)

func _draw_tentacles(squid: Squid, color: Color):
	if squid.trail.is_empty():
		return
	
	for i in range(squid.trail.size()):
		var point = squid.trail[i]
		
		draw_rect(Rect2(point.x - 1, point.y - 1, 2, 2), color)
		
		if i > squid.trail.size() / 2.0:
			var offset = squid.radius / 4.0
			draw_rect(Rect2(point.x - offset - 1, point.y - 1, 2, 2), color)
			draw_rect(Rect2(point.x + offset - 1, point.y - 1, 2, 2), color)
		
		if i > squid.trail.size() / 3.0:
			var offset = squid.radius / 10.0
			draw_rect(Rect2(point.x + offset - 1, point.y - 10, 2, 2), color)
			draw_rect(Rect2(point.x - offset - 1, point.y - 10, 2, 2), color)
