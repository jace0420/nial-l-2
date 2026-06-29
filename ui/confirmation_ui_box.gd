class_name ConfirmationUIBox extends Control

signal confirmed
signal cancelled

@onready var _titleLabel: Label = $VBoxContainer/TitleLabel
@onready var _yesButton: Button = $VBoxContainer/HBoxContainer/YesButton
@onready var _noButton: Button = $VBoxContainer/HBoxContainer/NoButton

func _ready() -> void:
	visible = false
	_yesButton.pressed.connect(_onYes)
	_noButton.pressed.connect(_onNo)

func showBox(title: String) -> void:
	_titleLabel.text = title
	visible = true
	_yesButton.grab_focus()

func _onYes() -> void:
	visible = false
	confirmed.emit()

func _onNo() -> void:
	visible = false
	cancelled.emit()
