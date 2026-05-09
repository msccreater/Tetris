# BagGenerator.gd - 7-bag 随机发生器
class_name BagGenerator

var _bag: Array[int] = []
var _predefined_sequence: Array = []
var _use_predefined: bool = false

func get_next() -> int:
	if _use_predefined:
		if not _predefined_sequence.is_empty():
			return _predefined_sequence.pop_front()
		_use_predefined = false
	if _bag.is_empty():
		refill()
	return _bag.pop_front()

func refill() -> void:
	_bag = [0, 1, 2, 3, 4, 5, 6]
	_bag.shuffle()

func set_sequence(seq: Array) -> void:
	_predefined_sequence = seq.duplicate()
	_use_predefined = true

func reset() -> void:
	_bag.clear()
	_predefined_sequence.clear()
	_use_predefined = false
	refill()
