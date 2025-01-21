extends Node

class_name InputManager

var pressed: Dictionary = {};
var held: Dictionary = {};
var released: Dictionary = {};

enum {INACTIVE, MENU, QUICKSWAP, PLAYER}
var current_state = INACTIVE

func _physics_process(_delta: float) -> void:
	# List of actions to monitor.
	var actions: Array[String] = ["up", "down", "left", "right", "a", "b", "start", "select"]
	
	# Iterate through all actions.
	for action in actions:
		var is_pressed = Input.is_action_pressed(action)
		var was_pressed = held.has(action) && held[action]
		
		if is_pressed && !was_pressed:
			# Button was just pressed.
			pressed[action] = true
			held[action] = true
			released[action] = false
		elif !is_pressed && was_pressed:
			# Button was just released.
			pressed[action] = false
			held[action] = false
			released[action] = true
		else:
			# Reset pressed/released flags after one frame.
			pressed[action] = false
			released[action] = false
			
func is_action_pressed(action: String) -> bool:
	# Check if an action was pressed this frame.
	return pressed.has(action) && pressed[action]

func is_action_held(action: String) -> bool:
	# Check if an action is currently being held.
	return held.has(action) && held[action]

func is_action_released(action: String) -> bool:
	# Check if an action was released this frame.
	return released.has(action) && released[action]

func get_x_dir() -> float:
	# Return the X direction being pressed/held.
	return int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))

func get_y_dir() -> float:
	# Return the Y direction being pressed/held.
	return int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
