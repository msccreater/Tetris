# Music.gd - 全局音效管理（Autoload）
extends Node

# 音效开关：0 关闭，其他值开启（与原 m_select 一致）
var m_select: int = 1

# 背景音乐播放器
var bgm_player: AudioStreamPlayer

# 预加载音频资源
const BGM_PATHS = [
	"res://assets/audio/bgm.mp3"
]

# 音效资源路径
const SFX = {
	"rotate": "res://assets/audio/rotate.mp3",
	"clear": "res://assets/audio/clear.mp3",
	"space": "res://assets/audio/space.mp3",
	"move": "res://assets/audio/move.mp3",
	"over": "res://assets/audio/over.mp3",
	"click": "res://assets/audio/click.mp3",
	"t1": "res://assets/audio/t1.mp3",
	"t2": "res://assets/audio/t2.mp3",
	"t3": "res://assets/audio/t3.mp3",
	"pc": "res://assets/audio/pc.mp3",
	"ok": "res://assets/audio/ok.mp3",
	"win": "res://assets/audio/win.mp3",
}

func _ready():
	# 创建背景音乐播放器并设置为循环
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"  # 使用音乐总线，方便单独调节音量
	bgm_player.stream = load(BGM_PATHS[0])
	bgm_player.finished.connect(_on_bgm_finished)
	add_child(bgm_player)

func _on_bgm_finished():
	# 循环播放
	bgm_player.play()

# ---------- 背景音乐控制 ----------
func play_bgm():
	if not Global.settings.music_enabled:
		return
	if not bgm_player.playing:
		bgm_player.volume_db = linear_to_db(Global.settings.music_volume)
		bgm_player.play()

func pause_bgm():
	bgm_player.stop()

func update_bgm(select: int):
	m_select = select
	if select > 0 and select <= 3:
		bgm_player.stream = load(BGM_PATHS[select - 1])
		bgm_player.stop()
	play_bgm()

# ---------- 播放短音效 ----------
func _play_sfx(sfx_name: String):
	if not Global.settings.sfx_enabled:
		return
	var path = SFX.get(sfx_name)
	if not path:
		return
	# 动态创建临时播放器（因为音效可能叠加）
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = load(path)
	player.volume_db = linear_to_db(Global.settings.sfx_volume)
	player.finished.connect(player.queue_free)  # 播放完毕自动释放
	add_child(player)
	player.play()
	# 备选：也可以预先创建多个播放器池，但简单新建即可，开销很小

func play_rotate():
	_play_sfx("rotate")

func play_move():
	_play_sfx("move")

func play_click():
	_play_sfx("click")

func play_space():
	_play_sfx("space")

func play_over():
	_play_sfx("over")

func play_ok():
	_play_sfx("ok")

func play_win():
	_play_sfx("win")

func play_tspin(type: int):
	if m_select == 0: return
	match type:
		6: _play_sfx("t1")
		7: _play_sfx("t2")
		8: _play_sfx("t3")
		9: _play_sfx("pc")
		_: _play_sfx("clear")   # 普通消行
