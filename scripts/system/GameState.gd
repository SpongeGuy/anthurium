extends Node

# -------------------------------------------
# autoload 
#
# -------------------------------------------


enum Status { LOADING, PLAYING, PAUSED, GAME_OVER, MENU }

var state: Status = Status.LOADING

signal game_state_changed(status: Status)

func change_game_state(status: Status) -> void:
	state = status
	game_state_changed.emit(state)
	


func toggle_pause() -> void:
	if state == Status.PLAYING:
		change_game_state(Status.PAUSED)
	elif state == Status.PAUSED:
		change_game_state(Status.PLAYING)
