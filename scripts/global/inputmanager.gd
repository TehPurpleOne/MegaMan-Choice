extends Node

class_name InputManager

var actions: Array[StringName] = InputMap.get_actions()

var is_pressed: Dictionary = {};
var is_held: Dictionary = {};
var is_released: Dictionary = {};

enum states {INACTIVE, MENU, QUICKSWAP, PLAYER}
var current_state: states = states.INACTIVE

func _physics_process(_delta: float) -> void:
	if(current_state == states.INACTIVE): return
	
	# Iterate through all actions.
	for action in actions:
		var button_down = Input.is_action_pressed(action)
		var button_release = is_held.has(action) && is_held[action]
		
		if button_down && !button_release:
			# Button was just pressed.
			is_pressed[action] = true
			is_held[action] = true
			is_released[action] = false
		elif !button_down && button_release:
			# Button was just released.
			is_pressed[action] = false
			is_held[action] = false
			is_released[action] = true
		else:
			# Reset pressed/released flags after one frame.
			is_pressed[action] = false
			is_released[action] = false
			
func pressed(action: String) -> bool:
	# Check if an action was pressed this frame.
	return is_pressed.has(action) && is_pressed[action]

func held(action: String) -> bool:
	# Check if an action is currently being held.
	return is_held.has(action) && is_held[action]

func released(action: String) -> bool:
	# Check if an action was released this frame.
	return is_released.has(action) && is_released[action]

func get_x_dir() -> float:
	# Return the X direction being pressed/held.
	return int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))

func get_y_dir() -> float:
	# Return the Y direction being pressed/held.
	return int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))

func set_state(new_state: states) -> void:
	if(new_state != states.PLAYER && new_state != states.QUICKSWAP):
		for action in actions:
			is_pressed[action] = false
			is_held[action] = false
			is_released[action] = false
			
	current_state = new_state
