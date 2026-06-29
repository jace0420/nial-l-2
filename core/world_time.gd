extends Node

## global clock: 24 in-game hours per real-time hour.
const TIME_SCALE := 24.0

## emitted each time the in-game minute changes.
signal tick(hour: int, minute: int)
signal dayChanged(day: int, month: int, year: int)

const _START_DAY_OF_WEEK := 0   # Sunday
const _START_DAY         := 1
const _START_MONTH       := 1
const _START_YEAR        := 900

const _DAYS_PER_MONTH := 30

const _DAY_NAMES   := ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
const _MONTH_NAMES := ["January","February","March","April","May","June",
                        "July","August","September","October","November","December"]

var _elapsed: float = 0.0       # cumulative game-seconds since session start
var _last_int_minute: int = -1

## when true, time stops advancing but keeps its accumulated value.
var paused: bool = false

var _day_of_week: int = _START_DAY_OF_WEEK
var _day:   int = _START_DAY
var _month: int = _START_MONTH
var _year:  int = _START_YEAR

var hour:   int = 0
var minute: int = 0


func setPaused(value: bool) -> void:
	paused = value


func _process(delta: float) -> void:
	if paused:
		return
	var prev := _elapsed
	_elapsed += delta * TIME_SCALE

	var prev_day_index := int(prev) / 86400
	var curr_day_index := int(_elapsed) / 86400
	for _i in range(curr_day_index - prev_day_index):
		_advanceDate()

	var today_secs := int(_elapsed) % 86400
	var new_minute := (today_secs / 60) % 60
	var new_hour   := today_secs / 3600

	if new_minute != _last_int_minute:
		_last_int_minute = new_minute
		hour   = new_hour
		minute = new_minute
		tick.emit(hour, minute)


func getTimeString() -> String:
	return "%02d:%02d" % [hour, minute]


## returns e.g. "Wednesday, January 0th, 900 CE"
func getDateString() -> String:
	return "%s, %s %s, %d CE" % [
		_DAY_NAMES[_day_of_week],
		_MONTH_NAMES[_month - 1],
		_ordinal(_day),
		_year
	]

func _advanceDate() -> void:
	_day_of_week = (_day_of_week + 1) % 7
	_day += 1
	if _day >= _DAYS_PER_MONTH:
		_day = 0
		_month += 1
		if _month > 12:
			_month = 1
			_year += 1
	dayChanged.emit(_day, _month, _year)


func _ordinal(n: int) -> String:
	var suffix: String
	if n in [11, 12, 13]:
		suffix = "th"
	else:
		match n % 10:
			1: suffix = "st"
			2: suffix = "nd"
			3: suffix = "rd"
			_: suffix = "th"
	return "%d%s" % [n, suffix]
