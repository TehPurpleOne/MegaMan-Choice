extends Node2D

class_name Initialize

var m: Master
var new_settings: MasterConfig = MasterConfig.new()

enum states {NULL, INIT, SAVEDEFAULT, CHECKDEFAULT, LOADNEXT}
var current_state: states = states.NULL
var previous_state: states = states.NULL

func _ready() -> void:
	m = get_node("/root/Master") as Master
	
	_set_state(states.INIT)

func _physics_process(delta: float) -> void:
	if(current_state != states.NULL):
		_state_logic(delta)
		var t: states = _get_transition(delta)
		if(t != states.NULL):
			_set_state(t)

func _state_logic(delta: float) -> void:
	pass

func _get_transition(delta: float) -> states:
	match current_state:
		states.INIT:
			if(m.current_state == Master.states.RUN): return states.SAVEDEFAULT
		
		states.SAVEDEFAULT:
			var path: String = m.CONFIG_PATH + m._get_extension()
			if(ResourceLoader.exists(path)): return states.CHECKDEFAULT
		
		states.CHECKDEFAULT:
			if(m._are_settings_valid()): return states.LOADNEXT
				
	return states.NULL

func _enter_state(new_state: states, old_state: states) -> void:
	match new_state:
		states.INIT:
			new_settings = MasterConfig.new()
			
			new_settings.scale = m.max_scale - 1
			
			for action in InputMap.get_actions():
				if(!new_settings.input_map.has(action)):
					var events: Array = []
					for ev in InputMap.action_get_events(action):
						events.append(ev.duplicate())
					new_settings.input_map_default[action] = events
					new_settings.input_map[action] = events
		
		states.SAVEDEFAULT:
			m._save_settings(new_settings)
		
		states.LOADNEXT:
			m._next_scene("res://scenes/game/title.tscn")

func _exit_state(old_state: states, new_state: states) -> void:
	pass

func _set_state(new_state: states) -> void:
	previous_state = current_state
	current_state = new_state
	
	_exit_state(previous_state, current_state)
	_enter_state(current_state, previous_state)
