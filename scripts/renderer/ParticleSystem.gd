class_name ParticleSystem
extends Node2D

## 作用: 每累积这么多秒，执行一次粒子更新
var _fixed_time_step: float = 1.0 / 60.0

## 【时间累积器】内部变量，记录距离上次更新过了多久
var _accumulated_time: float = 0.0


# ============================================================
# 粒子外观参数
# ============================================================

## 【角度扩散范围】粒子喷射方向的左右摇摆幅度
## 单位: 弧度。PI = 180°, PI/2 = 90°, PI/6 = 30°
## 效果: 值越大，粒子散得越开呈扇形；值越小，越集中呈直线
## 建议: 尾焰效果 0.1~0.3，爆炸效果 1.0~3.0
@export var angle_spread: float = PI / 18.0

## 【基础喷射角度】粒子喷射的基准方向
## 单位: 弧度。1.57 ≈ 90° = 正下方
## 效果: 0 = 向右, PI/2 = 向下, PI = 向左, PI*1.5 = 向上
## 建议: 根据飞船朝向动态调整，或保持向下模拟推进器
@export var base_angle: float = 1.57

## 【速度倍率】粒子初始飞行速度的放大系数
## 效果: 值越大，粒子飞得越快越远；值越小，越慢越短
## 建议: 1.0~3.0
@export var speed_multiplier: float = 1.0

## 【半径最小值】粒子大小的随机下限
## 效果: 决定粒子最小有多大。越大粒子越明显，越小越细腻
## 建议: 2~6
@export var radius_min: float = 4.0

## 【半径最大值】粒子大小的随机上限
## 效果: 决定粒子最大有多大。和 radius_min 配合控制大小差异
## 建议: 6~12
@export var radius_max: float = 7.0


# ============================================================
# 粒子生命周期参数
# ============================================================

## 【生命周期】粒子从生成到消失的帧数
## 效果: 值越大，粒子存在越久，尾焰拖得越长
## 建议: 80~300。太短像火花，太长像烟雾
@export var life_span_default: int = 80

## 【摩擦力】每帧速度衰减的比例
## 效果: 1.0 = 无摩擦永不减速；0.9 = 快速减速；0.99 = 缓慢减速
## 建议: 0.95~0.995。越小粒子越快停止，尾焰越短
@export var friction: float = 0.98

## 【半径衰减】每帧粒子缩小的量
## 效果: 值越大，粒子越快缩小到看不见；值越小，保持大小越久
## 建议: 0.02~0.1。配合 life_span 调整视觉持续时间
@export var radius_decay: float = 0.1

## 【半径下限】粒子最小保留大小
## 效果: 防止粒子缩到 0 导致渲染问题。视觉上 0.1 已经看不见了
## 建议: 保持 0.1
@export var radius_limit: float = 0.1


# ============================================================
# 粒子类 (内部使用，无需修改)
# ============================================================

class Particle:
	# 【半径】当前粒子大小，影响矩形绘制尺寸
	var radius: float

	# 【颜色】粒子颜色，JS 原始为 rgba(20, 110, 250, 0.4) 半透明蓝
	var color: Color

	# 【剩余生命】倒计时，到 0 以下时标记为 blacklisted 回收
	var life_span: int

	# 【摩擦系数】每帧 vel *= fric，复制自父节点参数
	var fric: float

	# 【位置】当前坐标，每帧 += vel
	var pos: Vector2

	# 【速度】每帧移动的方向和距离，受 friction 衰减
	var vel: Vector2

	# 【回收标记】true 表示该粒子已死亡，下一帧归还对象池
	var blacklisted: bool

	func _init() -> void:
		radius = 2.0
		color = Color.WHITE
		life_span = 0
		fric = 0.98
		pos = Vector2.ZERO
		vel = Vector2.ZERO
		blacklisted = false

	# 【粒子更新】每帧执行一次，JS 原始逻辑:
	# 1. 按速度移动位置
	# 2. 速度按 friction 衰减
	# 3. 半径缩小 radius_decay
	# 4. 生命倒计时，归零后标记死亡
	func update() -> void:
		pos += vel
		vel *= fric
		radius -= 0.1
		if radius < 0.1:
			radius = 0.1
		var current_life: int = life_span
		life_span -= 1
		if current_life < 0:
			blacklisted = true

	func reset() -> void:
		blacklisted = false


# ============================================================
# 对象池 (内部使用，无需修改)
# 作用: 预创建 24 个粒子循环利用，避免频繁 new/delete 造成 GC 卡顿
# ============================================================

class ObjectPool:
	var _type: GDScript
	var _size: int
	var _pointer: int
	var _elements: Array = []

	func init(type: GDScript, size: int) -> void:
		_type = type
		_size = size
		_pointer = size
		_elements = []
		var i: int = 0
		var n: int = _size
		while i < n:
			_elements.append(_type.new())
			i += 1

	func get_element() -> Particle:
		if _pointer > 0:
			_pointer -= 1
			return _elements[_pointer]
		return null

	func dispose_element(element: Particle) -> void:
		_elements[_pointer] = element
		_pointer += 1


# ============================================================
# 模块级变量 (内部使用)
# ============================================================

var _pool: ObjectPool          # 对象池实例，管理 24 个粒子复用
var _active_particles: Array   # 当前活跃的粒子列表


# ============================================================
# 粒子系统方法
# ============================================================

## 【初始化】创建对象池，预先生成 24 个粒子备用
func particle_init() -> void:
	_pool = ObjectPool.new()
	_pool.init(Particle, 24)
	_active_particles = []

## 【更新所有粒子】遍历活跃粒子，死亡的回收，活着的执行 update()
func update_particles() -> void:
	var t: int = _active_particles.size() - 1
	while t > -1:
		var e: Particle = _active_particles[t]
		if e.blacklisted:
			e.reset()
			_active_particles.remove_at(_active_particles.find(e))
			_pool.dispose_element(e)
		else:
			e.update()
		t -= 1

## 【渲染所有粒子】用矩形绘制每个活跃粒子，80% 概率填充(20%透明闪烁)
func render_particles() -> void:
	var e_idx: int = _active_particles.size() - 1
	while e_idx > -1:
		var i: Particle = _active_particles[e_idx]
		var rect_x: float = (int(i.pos.x) >> 0) - i.radius
		var rect_y: float = (int(i.pos.y) >> 0) - i.radius
		var rect_w: float = 2.0 * i.radius
		var rect_h: float = 2.0 * i.radius
		if randf() > 0.2:
			draw_rect(Rect2(rect_x, rect_y, rect_w, rect_h), i.color, true)
		e_idx -= 1

## 【生成推进粒子】在指定位置创建一个新的尾焰粒子
## x, y: 生成位置 (通常是飞船尾部坐标)
func generate_thrust_particle(x: float, y: float) -> void:
	var s: Particle = _pool.get_element()
	if s == null:
		return
	# 随机大小: radius_min ~ radius_max
	s.radius = (radius_max - radius_min) * randf() + radius_min
	# 固定颜色: 半透明蓝色
	s.color = Color(20.0 / 255.0, 110.0 / 255.0, 250.0 / 255.0, 0.4)
	# 设置生命周期
	s.life_span = life_span_default
	# 设置初始位置
	s.pos = Vector2(x, y)
	# 计算速度: 方向 = base_angle ± angle_spread，大小 = 8/radius * speed_multiplier
	var angle: float = base_angle + (1.0 - 2.0 * randf()) * angle_spread
	var length: float = (8.0 / s.radius) * speed_multiplier
	s.vel = Vector2.from_angle(angle)
	s.vel = s.vel.normalized() * length
	# 反向 (模拟从飞船向后喷射)
	s.vel *= -1.0
	# 加入活跃列表
	_active_particles.append(s)


# ============================================================
# Godot 节点生命周期
# ============================================================

func _ready() -> void:
	particle_init()

## 【主循环】按 target_fps 固定步长更新粒子，不受显示器帧率影响
func _process(delta: float) -> void:
	_accumulated_time += delta
	while _accumulated_time >= _fixed_time_step:
		update_particles()
		_accumulated_time -= _fixed_time_step
	queue_redraw()

func _draw() -> void:
	render_particles()


# ============================================================
# 便捷方法
# ============================================================

## 【发射尾焰】在指定世界坐标生成一个推进粒子
## 用法: particle_system.emit_thrust(global_position)
func emit_thrust(at_position: Vector2) -> void:
	generate_thrust_particle(at_position.x, at_position.y)
