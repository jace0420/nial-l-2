class_name DiceManager extends Node

enum Die { D4 = 4, D6 = 6, D8 = 8, D10 = 10, D12 = 12, D20 = 20, D100 = 100 }


func roll(die: Die, count: int = 1, modifier: int = 0) -> DiceResult:
	var result: DiceResult = DiceResult.new()
	result.die_faces = int(die)
	result.modifier = modifier
	for _i: int in count:
		result.rolls.append(_roll_single(die))
	var sum: int = 0
	for r: int in result.rolls:
		sum += r
	result.total = sum + modifier
	if die == Die.D20 and count == 1:
		result.is_critical = result.rolls[0] == 20
		result.is_fumble = result.rolls[0] == 1
	EventBus.diceRolled.emit(result)
	return result


func roll_advantage(modifier: int = 0) -> DiceResult:
	return _roll_keep(Die.D20, 2, 1, modifier, true)


func roll_disadvantage(modifier: int = 0) -> DiceResult:
	return _roll_keep(Die.D20, 2, 1, modifier, false)


# e.g. roll_keep_highest(Die.D6, 4, 3) for stat generation.
func roll_keep_highest(die: Die, count: int, keep: int, modifier: int = 0) -> DiceResult:
	return _roll_keep(die, count, keep, modifier, true)


func roll_keep_lowest(die: Die, count: int, keep: int, modifier: int = 0) -> DiceResult:
	return _roll_keep(die, count, keep, modifier, false)


func _roll_keep(die: Die, count: int, keep: int, modifier: int, keep_highest: bool) -> DiceResult:
	var result: DiceResult = DiceResult.new()
	result.die_faces = int(die)
	result.modifier = modifier
	var all_rolls: Array[int] = []
	for _i: int in count:
		all_rolls.append(_roll_single(die))
	all_rolls.sort()
	if keep_highest:
		all_rolls.reverse()
	result.rolls = all_rolls.slice(0, keep)
	result.dropped = all_rolls.slice(keep)
	var sum: int = 0
	for r: int in result.rolls:
		sum += r
	result.total = sum + modifier
	if die == Die.D20 and keep == 1:
		result.is_critical = result.rolls[0] == 20
		result.is_fumble = result.rolls[0] == 1
	EventBus.diceRolled.emit(result)
	return result


func _roll_single(die: Die) -> int:
	return randi() % int(die) + 1
