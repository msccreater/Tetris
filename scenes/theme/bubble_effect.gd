extends Node2D

class_name BubbleEffect

class Bubble:
	var x: float
	var y: float
	var scale: float
	var scale_change: float
	var speed: float
	var color: Color
	
	func _init(screen_w: float, screen_h: float, colors: Array[Color]):
		reset(screen_w, screen_h, colors, true)
	
	func reset(screen_w: float, screen_h: float, colors: Array[Color], initial: bool = false):
		var color_idx = randi() % colors.size()
		color = colors[color_idx]
		
		x = randf() * screen_w
		# 初始时随机分布，重置时从底部出现
		if initial:
			y = randf() * screen_h
		else:
			y = screen_h - 10
		
		# scale: 30 ~ 60 (n(30, 60))
		scale = float(randi() % 31 + 30)
		# scale_change: 0 ~ 0.002 (0.002 * Math.random())
		scale_change = 0.002 * randf()
		# speed: 0.1 ~ 0.5 (0.1 + 0.4 * Math.random())
		speed = (0.1 + 0.4 * randf()) * 60.0  # 转换为每秒像素
	
	func update(delta: float, _screen_h: float, offset: float):
		# 超出顶部检测: y <= -50
		if y <= -50:
			return false  # 需要重置
		
		# 上升: y -= speed
		y -= speed * delta
		# 缩放: scale += scale_change
		scale += scale_change * 60.0 * delta
		# 水平偏移: x += offset
		x += offset * 60.0 * delta
		
		return true

# 8种颜色，0.2透明度
var bubble_colors: Array[Color] = [
	Color8(236, 112, 99, 51),    # rgba(236, 112, 99, 0.2) 珊瑚红
	Color8(165, 105, 189, 51),   # rgba(165, 105, 189, 0.2) 紫色
	Color8(93, 173, 226, 51),    # rgba(93, 173, 226, 0.2) 天蓝
	Color8(69, 179, 157, 51),    # rgba(69, 179, 157, 0.2) 青绿
	Color8(88, 214, 141, 51),    # rgba(88, 214, 141, 0.2) 浅绿
	Color8(244, 208, 63, 51),    # rgba(244, 208, 63, 0.2) 黄色
	Color8(235, 152, 78, 51),    # rgba(235, 152, 78, 0.2) 橙色
	Color8(230, 176, 170, 51)    # rgba(230, 176, 170, 0.2) 粉红
]

var bubbles: Array[Bubble] = []
var screen_size: Vector2

@export var debug_mode: bool = false
const BUBBLE_COUNT: int = 16
var horizontal_offset: float = 0.0  # 对应原代码的 o

func _ready():
	Engine.max_fps = 60
	screen_size = get_viewport_rect().size
	_init_bubbles()

func _init_bubbles():
	bubbles.clear()
	for i in range(BUBBLE_COUNT):
		bubbles.append(Bubble.new(screen_size.x, screen_size.y, bubble_colors))

func _process(delta):
	# 更新所有气泡
	for bubble in bubbles:
		var alive = bubble.update(delta, screen_size.y, horizontal_offset)
		if not alive:
			bubble.reset(screen_size.x, screen_size.y, bubble_colors, false)
	
	queue_redraw()

func _draw():
	# 绘制深色背景
	draw_rect(Rect2(0, 0, screen_size.x, screen_size.y), Color8(10, 20, 40, 255))
	
	# 绘制所有气泡
	for bubble in bubbles:
		# 超出屏幕底部不绘制 (y > h + 50)
		if bubble.y > screen_size.y + 50:
			continue
		
		# 绘制矩形: rect(x, y, scale, scale)
		draw_rect(Rect2(bubble.x, bubble.y, bubble.scale, bubble.scale), bubble.color)
	
	# 绘制UI
	if debug_mode:
		_draw_ui()

func _draw_ui():
	var margin: float = 15.0
	var ui_x: float = margin
	var ui_y: float = margin
	
	draw_rect(Rect2(ui_x - 5, ui_y - 5, 280, 100), Color8(0, 0, 0, 150))
	
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 15), "🫧 气泡效果", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(100, 200, 255, 255))
	
	var status_color = Color8(255, 255, 255, 220)
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 40), "气泡: %d 个" % BUBBLE_COUNT, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, status_color)
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 60), "偏移: %.1f" % horizontal_offset, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, status_color)
	
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 85), "[←/→] 调整偏移  [R] 重置", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(200, 200, 200, 200))

# 设置水平偏移 (对应原代码 set_offset)
func set_offset(offset: float):
	horizontal_offset = offset

func reset():
	horizontal_offset = 0.0
	_init_bubbles()

func _input(event):
	if not debug_mode: return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				horizontal_offset -= 1.0
			KEY_RIGHT:
				horizontal_offset += 1.0
			KEY_R:
				reset()
