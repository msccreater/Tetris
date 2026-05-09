extends Node2D

class_name SnowEffect

class Snowflake:
	var type: int          # 0~6，雪花类型
	var posx: float
	var posy: float
	var rect_w: float = 56.0
	var rect_h: float = 56.0
	var hide: bool = false
	
	func _init(screen_w: float, screen_h: float, type_counter: int):
		# type = ++o % 7
		type = type_counter % 7
		# 随机X位置: n(0, r)
		posx = randf() * screen_w
		# 随机Y位置: h * Math.random()
		posy = randf() * screen_h
		hide = false
	
	func reset(screen_w: float, _screen_h: float):
		# 超出底部后重置到顶部
		posy = -50
		posx = randf() * screen_w
	
	func update(delta: float, screen_h: float, screen_w: float, offset: float) -> bool:
		# 下落: posy++ (1像素/帧 = 60像素/秒)
		posy += 60.0 * delta
		
		# 水平偏移
		posx += offset * 60.0 * delta
		
		# 超出底部检测: posy > h + 50
		if posy > screen_h + 50:
			reset(screen_w, screen_h)
			return true  # 已重置
		
		return false

var snow_list: Array[Snowflake] = []
var screen_size: Vector2

const SNOW_COUNT: int = 8
const SNOW_TYPES: int = 7
const ATLAS_CELL_SIZE: float = 128.0  # 每个雪花在精灵表中的大小

# 雪花图片资源路径
@export var debug_mode: bool = false
@export var snow_texture: Texture2D

# 水平偏移
var horizontal_offset: float = 0.0

# 类型计数器（用于分配不同类型的雪花）
var type_counter: int = 0

func _ready():
	Engine.max_fps = 60
	screen_size = get_viewport_rect().size
	
	# 加载默认图片（如果未在编辑器中设置）
	if snow_texture == null:
		# 尝试从路径加载
		snow_texture = load("res://assets/images/snow.png")
	
	_init_snowflakes()

func _init_snowflakes():
	snow_list.clear()
	type_counter = 0
	
	for i in range(SNOW_COUNT):
		type_counter += 1
		var snow = Snowflake.new(screen_size.x, screen_size.y, type_counter)
		snow_list.append(snow)

func _process(delta):
	for snow in snow_list:
		snow.update(delta, screen_size.y, screen_size.x, horizontal_offset)
	
	queue_redraw()

func _draw():
	# 绘制深色背景
	draw_rect(Rect2(0, 0, screen_size.x, screen_size.y), Color8(20, 30, 50, 255))
	
	# 绘制所有雪花
	if snow_texture != null:
		for snow in snow_list:
			if snow.hide:
				continue
			
			_draw_snowflake(snow)
	else:
		# 如果没有图片，用白色方块代替
		for snow in snow_list:
			draw_rect(Rect2(snow.posx, snow.posy, snow.rect_w, snow.rect_h), Color8(255, 255, 255, 200))
	
	# 绘制UI
	if debug_mode:
		_draw_ui()

func _draw_snowflake(snow: Snowflake):
	# 计算精灵表中的源区域
	# src_x = 128 * type, src_y = 0, src_w = 128, src_h = 128
	var src_rect = Rect2(
		ATLAS_CELL_SIZE * snow.type,  # x
		0.0,                           # y
		ATLAS_CELL_SIZE,               # width
		ATLAS_CELL_SIZE                # height
	)
	
	# 目标绘制区域
	var dst_rect = Rect2(
		snow.posx,
		snow.posy,
		snow.rect_w,
		snow.rect_h
	)
	
	# 使用 draw_texture_rect_region 绘制精灵表的一部分
	draw_texture_rect_region(snow_texture, dst_rect, src_rect)

func _draw_ui():
	var margin: float = 15.0
	var ui_x: float = margin
	var ui_y: float = margin
	
	draw_rect(Rect2(ui_x - 5, ui_y - 5, 300, 110), Color8(0, 0, 0, 150))
	
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 15), "❄️ 雪花效果", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(200, 230, 255, 255))
	
	var status_color = Color8(255, 255, 255, 220)
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 40), "雪花: %d 片 (7种形状)" % SNOW_COUNT, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, status_color)
	
	var texture_status = "已加载" if snow_texture != null else "未找到图片"
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 60), "图片: %s" % texture_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, status_color)
	
	draw_string(ThemeDB.fallback_font, Vector2(ui_x, ui_y + 85), "[←/→] 风向偏移: %.1f  [R] 重置" % horizontal_offset, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(200, 200, 200, 200))

# 设置水平偏移（模拟风向）
func set_offset(offset: float):
	horizontal_offset = offset

func reset():
	horizontal_offset = 0.0
	_init_snowflakes()

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
