extends Node2D

class_name Title

var m: Master

enum states {NULL, INIT, INITDONE, SELECT, LOADNEXT, KILLGAME}
var current_state: states = states.NULL
var previous_state: states = states.NULL

var menu_pos: int = 0
var last_pos: int = 0
var max_menu_pos: int = 0
var cursor_start_pos: Vector2i = Vector2i.ZERO

func _ready() -> void:
	m = get_node("/root/Master")
	
	_set_state(states.INIT)

func _physics_process(delta: float) -> void:
	if(current_state != states.NULL):
		_state_logic(delta)
		var t: states = _get_transition(delta)
		if(t != states.NULL): _set_state(t)

func _state_logic(delta: float) -> void:
	match current_state:
		states.SELECT:
			if(im.pressed("up") || im.pressed("down")):
				menu_pos = clamp(menu_pos + im.get_y_dir(), 0, max_menu_pos)
				if(_skip_selection(menu_pos)): menu_pos = clamp(menu_pos + im.get_y_dir(), 0, max_menu_pos)
				if(last_pos != menu_pos):
					m._play_sound("cursor")
					_update_cursor_pos(menu_pos)
					last_pos = menu_pos

func _get_transition(delta: float) -> states:
	match current_state:
		states.INIT:
			if m.current_state == Master.states.LOADED: return states.INITDONE
		
		states.INITDONE:
			if m.current_state == Master.states.RUN: return states.SELECT
		
		states.SELECT:
			if(im.pressed("accept") || im.pressed("start")):
				match _get_line(menu_pos):
					"GAME START": return states.LOADNEXT
					"EXIT": return states.KILLGAME
			
	return states.NULL

func _enter_state(new_state: states, old_state: states) -> void:
	match new_state:
		states.INIT:
			cursor_start_pos = $cursor.position
			var split_lines: PackedStringArray = $options.text.split("\n")
			var lines: Array[String] = []
			for line in split_lines:
				lines.append(line)
			max_menu_pos = lines.size() - 1
		
		states.INITDONE:
			m._set_state(Master.states.FADEIN)
		
		states.LOADNEXT:
			m._next_scene("res://scenes/game/gameworld.tscn")
		
		states.KILLGAME:
			get_tree().quit()

func _exit_state(old_state: states, new_state: states) -> void:
	match old_state:
		states.INIT:
			m._play_music("Menu")
			$cursor.show()
			im.set_state(InputManager.states.MENU)

func _set_state(new_state: states) -> void:
	previous_state = current_state
	current_state = new_state
	
	_exit_state(previous_state, current_state)
	_enter_state(current_state, previous_state)

func _update_cursor_pos(pos: int) -> void:
	$cursor.position = cursor_start_pos + Vector2i(0, 8 * pos)
	
func _skip_selection(pos: int) -> bool:
	if(_get_line(pos) == ""): return true
	
	return false

func _get_line(pos: int) -> String:
	var split_lines: PackedStringArray = $options.text.split("\n")
	var lines: Array[String] = []
	for line in split_lines:
		lines.append(line)
	var result: String = lines[pos]
	return result
