extends Control

@onready var check_music: CheckBox = %CheckMusic
@onready var check_sfx: CheckBox = %CheckSfx
@onready var das_slider: HSlider = %DASSlider
@onready var das_value: SpinBox = %DASValue
@onready var arr_slider: HSlider = %ARRSlider
@onready var arr_value: SpinBox = %ARRValue
@onready var soft_das_slider: HSlider = %SoftDASSlider
@onready var soft_das_value: SpinBox = %SoftDASValue
@onready var soft_arr_slider: HSlider = %SoftARRSlider
@onready var soft_arr_value: SpinBox = %SoftARRValue
@onready var reset_btn: Button = %ResetBtn
@onready var back_btn: Button = %BackBtn
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	load_ui_from_settings()
	check_music.toggled.connect(_on_music_toggled)
	check_sfx.toggled.connect(_on_sfx_toggled)
	das_slider.value_changed.connect(_on_setting_changed)
	das_value.value_changed.connect(_on_setting_changed)
	arr_slider.value_changed.connect(_on_setting_changed)
	arr_value.value_changed.connect(_on_setting_changed)
	soft_das_slider.value_changed.connect(_on_setting_changed)
	soft_das_value.value_changed.connect(_on_setting_changed)
	soft_arr_slider.value_changed.connect(_on_setting_changed)
	soft_arr_value.value_changed.connect(_on_setting_changed)
	reset_btn.pressed.connect(_on_reset)
	back_btn.pressed.connect(_on_back)
	_connect_slider_spin(das_slider, das_value)
	_connect_slider_spin(arr_slider, arr_value)
	_connect_slider_spin(soft_das_slider, soft_das_value)
	_connect_slider_spin(soft_arr_slider, soft_arr_value)
	anim.play("fade_in")

func _connect_slider_spin(slider: HSlider, spin: SpinBox):
	slider.value_changed.connect(spin.set_value_no_signal)
	spin.value_changed.connect(slider.set_value_no_signal)

func load_ui_from_settings():
	var s = Global.settings
	check_music.button_pressed = s.music_enabled
	check_sfx.button_pressed = s.sfx_enabled
	das_slider.value = s.das_delay
	das_value.value = s.das_delay
	arr_slider.value = s.arr_interval
	arr_value.value = s.arr_interval
	soft_das_slider.value = s.down_das
	soft_das_value.value = s.down_das
	soft_arr_slider.value = s.down_arr
	soft_arr_value.value = s.down_arr

func save_ui_to_settings():
	var s = Global.settings
	s.music_enabled = check_music.button_pressed
	s.sfx_enabled = check_sfx.button_pressed
	s.das_delay = das_slider.value
	s.arr_interval = arr_slider.value
	s.down_das = soft_das_slider.value
	s.down_arr = soft_arr_slider.value

func _on_music_toggled(_pressed: bool):
	_save_all()

func _on_sfx_toggled(_pressed: bool):
	_save_all()

func _on_setting_changed(_value: float):
	_save_all()

func _save_all():
	save_ui_to_settings()
	Global.save_settings()

func _on_reset():
	check_music.button_pressed = true
	check_sfx.button_pressed = true
	das_slider.value = 12.0
	arr_slider.value = 1.0
	soft_das_slider.value = 8.0
	soft_arr_slider.value = 1.0

func _on_back():
	_save_all()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back()
