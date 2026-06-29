## renders log lines into the on-screen log. owns no game logic — it only listens for
## EventBus.logMessagePosted and instantiates a log entry per message.
class_name LogManager extends Node

## entries beyond this are pruned oldest-first so the log can't grow unbounded.
const MAX_ENTRIES: int = 200

const LOG_ENTRY_SCENE: PackedScene = preload("res://ui/log_entry.tscn")
const LABEL_PATH: NodePath = ^"LogRichTextLabel"

@export var logContainerPath: NodePath
@export var logScrollPath: NodePath

@onready var _logContainer: VBoxContainer = get_node(logContainerPath) as VBoxContainer
@onready var _logScroll: ScrollContainer = get_node(logScrollPath) as ScrollContainer


func _ready() -> void:
	EventBus.logMessagePosted.connect(_onLogMessagePosted)


func _onLogMessagePosted(text: String, color: Color) -> void:
	var entry: Control = LOG_ENTRY_SCENE.instantiate() as Control
	var label: RichTextLabel = entry.get_node(LABEL_PATH) as RichTextLabel
	# each entry leads with a timestamp; the time is read after any travel advance, so it
	# reflects the moment the event resolved.
	label.text = "[color=#%s][%s] %s[/color]" % [color.to_html(false), WorldTime.getTimeString(), text]
	_logContainer.add_child(entry)
	_pruneOldest()
	_scrollToBottom()


func _pruneOldest() -> void:
	while _logContainer.get_child_count() > MAX_ENTRIES:
		var oldest: Node = _logContainer.get_child(0)
		_logContainer.remove_child(oldest)
		oldest.queue_free()


func _scrollToBottom() -> void:
	# wait one frame so the container re-lays-out and the scrollbar's max grows first.
	await get_tree().process_frame
	_logScroll.scroll_vertical = int(_logScroll.get_v_scroll_bar().max_value)
