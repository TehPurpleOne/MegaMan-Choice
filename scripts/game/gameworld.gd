extends Node2D

class_name GameWorld

var active_section

enum states {
	NULL,
	INITIALIZE,
	READY,
	RUN
}

var im: InputManager

var current_state: states = states.NULL
var previous_state: states = states.NULL

var ticker: int = 0

# This is the game world. It will house all of the stages within your game along with any objects that
# are not dynamically loaded into the scene. I'll give a breakdown of what each function does as we
# get to them.

func _ready() -> void:
	im = get_node("/root/im")
	_set_state(states.INITIALIZE)

func _physics_process(delta: float) -> void:
	# This is a very simple finite state machine that I use in nearly all of my scripts. This setup allows
	# devs to create specific triggers to move onto a new state, along with the potential of additional
	# polish as states are exited as well.
	if(current_state != states.NULL):
		_state_logic(delta)
		var t: states = _get_transition(delta)
		if(t != states.NULL):
			_set_state(t)

func _state_logic(delta: float) -> void:
	# Actual state logic will be handled here. Usually with a MATCH statement.
	match current_state:
		states.READY:
			pass
	
	# The ticker will constantly be counting up. Only resetting when a state change occurs.
	ticker += 1
	
func _get_transition(delta: float) -> states:
	# Each frame, specific triggers for the active state is checked. If true, it loads the next state. Simple.
	match current_state:
		states.INITIALIZE:
			if $Graphic/MegaMan.global_position != Vector2.ZERO: return states.READY
		
		states.READY:
			if ticker == 180: return states.RUN
			
	return states.NULL

func _enter_state(new_state: states, old_state: states):
	# Enter a new state.
	match new_state:
		states.INITIALIZE:
			# Place the player onto the selected spawn point.
			var m = get_tree().get_nodes_in_group("Master")[0]
			for sp in get_tree().get_nodes_in_group("SpawnPoint"):
				if sp.spawnID == m.levelID:
					$Graphic/MegaMan.global_position = sp.global_position
					$Graphic/MegaMan.spawn_y_pos = sp.global_position.y
		
		states.READY:
				$AnimationPlayer.play("READY")
			
		states.RUN:
				$AnimationPlayer.play("RESET")
				im.current_state = InputManager.states.PLAYER

func _exit_state(old_state: states, new_state: states):
	# Exit an old state.
	pass

func _set_state(new_state: states):
	previous_state = current_state
	current_state = new_state
	
	for stname in states.keys():
		if states[stname] == current_state: print(name,", is now in state: ",stname);
	
	ticker = 0
	
	_exit_state(previous_state, current_state)
	_enter_state(current_state, previous_state)
	
