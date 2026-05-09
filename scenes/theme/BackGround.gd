extends CanvasLayer

var current_bg = 0
var bg_nodes: Array = []

func _ready() -> void:
	for child in get_children():
		if child is Node2D:
			bg_nodes.append(child)
			child.visible = false
			child.set_process(false)
	var saved = 0
	switch_bg(saved)

func switch_bg(idx: int = 0):
	if idx < 0 or idx >= bg_nodes.size():
		push_warning("背景 %d 不存在'" % idx)
		return
	
	# 隐藏当前背景
	if idx != current_bg:
		bg_nodes[current_bg].visible = false
		bg_nodes[current_bg].set_process(false)
	
	# 显示新背景
	var new_bg = bg_nodes[idx]
	new_bg.visible = true
	new_bg.set_process(true)
	current_bg = idx
	
	# 保存选择
	#Global.set_setting("dynamic_bg", current_bg)
