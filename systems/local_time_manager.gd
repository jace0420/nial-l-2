extends Node

## Connects the WorldTime singleton to the HUD clock and date labels.

@export var timeLabelPath: NodePath
@export var dateLabelPath: NodePath

@onready var _timeLabel: Label = get_node(timeLabelPath)
@onready var _dateLabel: Label = get_node(dateLabelPath)


func _ready() -> void:
	WorldTime.tick.connect(_onTick)
	WorldTime.dayChanged.connect(_onDayChanged)
	_timeLabel.text = WorldTime.getTimeString()
	_dateLabel.text = WorldTime.getDateString()


func _onTick(_hour: int, _minute: int) -> void:
	_timeLabel.text = WorldTime.getTimeString()


func _onDayChanged(_day: int, _month: int, _year: int) -> void:
	_dateLabel.text = WorldTime.getDateString()
