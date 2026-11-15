extends Control

const NAME_COLUMN_WIDTH := 220.0
const COUNT_COLUMN_WIDTH := 72.0
const STAT_COLUMN_WIDTH := 180.0

const STARTER_ROWS: Array[Dictionary] = [
	{"name": "Rusty Sword", "count": 1, "stat": "ATK +4"},
	{"name": "Leather Vest", "count": 1, "stat": "DEF +2"},
	{"name": "Minor Potion", "count": 3, "stat": "Heal 20 HP"},
]

@onready var _grid: GridContainer = %Grid

func _ready() -> void:
	_fill_grid()


func _fill_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_add_cell("Item", NAME_COLUMN_WIDTH, HORIZONTAL_ALIGNMENT_LEFT)
	_add_cell("Count", COUNT_COLUMN_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT)
	_add_cell("Stat", STAT_COLUMN_WIDTH, HORIZONTAL_ALIGNMENT_LEFT)
	for row in STARTER_ROWS:
		_add_cell(str(row["name"]), NAME_COLUMN_WIDTH, HORIZONTAL_ALIGNMENT_LEFT)
		_add_cell(str(int(row["count"])), COUNT_COLUMN_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT)
		_add_cell(str(row["stat"]), STAT_COLUMN_WIDTH, HORIZONTAL_ALIGNMENT_LEFT)


func _add_cell(text: String, min_width: float, alignment: HorizontalAlignment) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_width, 0.0)
	label.horizontal_alignment = alignment
	_grid.add_child(label)
