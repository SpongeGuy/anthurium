extends Node
class_name TimeManager

# -----------------------------------------------------------
# time keeps on slippin
# keeps the time and controls the day
# -----------------------------------------------------------


enum DayState { DAWN, DAY, DUSK, NIGHT }
const DAYTIMES: Array[int] = [0, 30, 60, 90]
var day_names: Array[String] = ["Dawn", "Day", "Dusk", "Fog"]

static var elapsed: float
var day_state: DayState

func _ready() -> void:
	GameState.game_state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(state: GameState.Status) -> void:
	if state == GameState.Status.PLAYING:
		change_day_state(DayState.DAWN)


func _process(delta: float) -> void:
	if GameState.state != GameState.Status.PLAYING:
		return
	_elapse(delta)
		
		
		
		

func change_day_state(state: DayState) -> void:
	day_state = state
	EventBus.day_state_changed.emit(state, day_names[state])
	match state:
		DayState.DAWN:
			EventBus.dawn_arrived.emit()
		DayState.DAY:
			EventBus.day_arrived.emit()
		DayState.DUSK:
			EventBus.dusk_arrived.emit()
		DayState.NIGHT:
			EventBus.night_arrived.emit()

func _elapse(delta: float) -> void:
	elapsed += delta

	# smart, emits only once when the time elapses enough to cause a change
	if day_state != DayState.NIGHT  and elapsed > DAYTIMES[day_state + 1]:
		change_day_state(day_state + 1)
