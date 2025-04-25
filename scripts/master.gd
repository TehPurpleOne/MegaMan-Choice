extends Node2D

class_name Master

# Required Nodes/Scripts
var music_tween: Tween = null

# Fields
const BASE_RES: Vector2 = Vector2(384, 224)
const MUSIC_BUS_INDEX: int = 1
const SOUND_BUS_INDEX: int = 2
const MUSIC_FADE_DURATION: float = 0.25
const CONFIG_PATH: String = "user://Settings"
const SAVES_PATH: String = "user://Saves"

var save_slot: int = 0

var sound_players: Array[AudioStreamPlayer] = []
var is_fading_music: bool = false
var queued_track: String = ""

var next_scene_path: String = ""
var max_load_time: float = 120.0

var settings: MasterConfig
var current_save: PlayerData
var temp_save: PlayerData

enum states {NULL, INIT, RUN, FADEOUT, FADEIN, LOAD, RELOCATE}
var current_state: states = states.NULL
var previous_state: states = states.NULL

# Video Properties
var fullscreen: bool = false
var connected_monitors: int = 0
var monitor: int = 0
var max_scale: int = 0
var current_scale: int = 1

# Audio Properties
var music_volume: float = 0.0
var sound_volume: float = 0.0
var charge_fade: bool = false
var mute_on_focus_loss: bool = false

# Game Function Variables
var relocate_player: bool = false
var has_focus: bool = false;

func _ready() -> void:
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
		states.FADEOUT:
			if(!$AnimationPlayer.is_playing() && !relocate_player): return states.LOAD
			if(!$AnimationPlayer.is_playing() && relocate_player): return states.RELOCATE
		
		states.FADEIN:
			if(!$AnimationPlayer.is_playing()):return states.RUN
			
	return states.NULL

func _enter_state(new_state: states, old_state: states) -> void:
	match new_state:
		states.INIT:
			# Set max scale.
			while(max_scale * BASE_RES.y < DisplayServer.screen_get_size(monitor).y): max_scale += 1
			if(max_scale * BASE_RES.y > DisplayServer.screen_get_size(monitor).y): max_scale -= 1
			if(max_scale > 18): max_scale = 18
			
			# Get number of connected displays.
			connected_monitors = DisplayServer.get_screen_count()
			
			# Sheck for the Master Config file. If it doesn't exist insitialize the game.
			var initialize: bool = !ResourceLoader.exists(CONFIG_PATH + _get_extension())
			if(initialize):
				_next_scene("res://scenes/game/initilize.tscn")
			else:
				_load_settings(CONFIG_PATH + _get_extension())
				_next_scene("res://scenes/game/title.tscn")
		
		states.LOAD:
			_load_scene()
		
		states.FADEOUT:
			$AnimationPlayer.play("FADEIN")
		
		states.FADEIN:
			$AnimationPlayer.play("FADE")

func _exit_state(old_state: states, new_state: states) -> void:
	pass

func _set_state(new_state: states) -> void:
	previous_state = current_state
	current_state = new_state
	
	print(name," has entered state: ",new_state)
	
	_exit_state(previous_state, current_state)
	_enter_state(current_state, previous_state)

# Window focus signal. Use to mute if mute_on_focus_loss is true.
func _notification(what: int) -> void:
	match what:
		DisplayServer.WINDOW_EVENT_FOCUS_IN: has_focus = true;
		
		DisplayServer.WINDOW_EVENT_FOCUS_OUT:
			pass

# Data saving/loading
func _load_settings(path: String) -> void:
	if(!ResourceLoader.exists(path)):
		push_error("Master Config file does not exist at %s" % path)
		return
	var resource: Resource = ResourceLoader.load(path)
	if(resource == null):
		push_error("Failed to load Master Config file at %s" % path)
		return
	_save_settings(resource)
	print("Master Config file was successfully loaded form %s" % path)
	
func _save_settings(data: MasterConfig) -> void:
	# Saves the config file fed to it.
	var file_path: String = CONFIG_PATH + _get_extension()
	var error: Error = ResourceSaver.save(data, file_path)
	if(error != OK):
		print("Failed to save Master Config at %s: %s" % [file_path, error_string(error)])
		return
	print("Master Config saved successfully at %s" % file_path)
	settings = data
	_apply_settings()

func _apply_settings() -> void:
	# Applies the recently saved settings to the needed variables.
	fullscreen = settings.fullscreen
	monitor = settings.monitor
	current_scale = settings.scale
	music_volume = settings.music_volume
	sound_volume = settings.sound_volume
	charge_fade = settings.charge_fade
	mute_on_focus_loss = settings.mute_on_focus_loss
	
	for action in InputMap.get_actions():
		InputMap.action_erase_events(action)
		if(settings.input_map.has(action)):
			var events: Array = settings.input_map[action]
			for ev in events:
				InputMap.action_add_event(action, ev)
	
	_update_video()
	_update_audio()

func _are_settings_valid() -> bool:
	# Will return true if all settings match within the game and settings file.
	return fullscreen == settings.fullscreen && \
		monitor == settings.monitor && \
		current_scale == settings.scale && \
		music_volume == settings.music_volume && \
		sound_volume == settings.sound_volume && \
		charge_fade == settings.charge_fade && \
		mute_on_focus_loss == settings.mute_on_focus_loss
	
	return false

func _save_player_data(data: PlayerData) -> void:
	# Saves the player data file fed to it.
	var file_path: String = SAVES_PATH + str(save_slot) + _get_extension()
	var error: Error = ResourceSaver.save(data, file_path)
	if(error != OK):
		print("Failed to save Player Data at %s: %s" % [file_path, error_string(error)])
		return
	print("Player Data saved successfully at %s" % file_path)

func _get_extension() -> String:
	var extension: String = ""
	
	if(!Engine.is_editor_hint()):
		extension = ".tres"
	else:
		extension = ".res"
	
	return extension

# Scene loading
func _next_scene(path: String) -> void:
	next_scene_path = path
	print("Attempting to load %s" % path)
	if($SceneManager.get_child_count() < 1):
		_set_state(states.LOAD)
		print("Loading scene...")
	else:
		_set_state(states.FADEOUT)
		print("Fading out...")

func _load_scene() -> void:
	$load_bar.show()
	
	# Start thread loading
	ResourceLoader.load_threaded_request(next_scene_path)
	
	if($load_bar == null):
		push_error("Error occurred. Load bar is not present.")
		return
	
	# Clear existing scenes in the scene root.
	if($SceneManager.get_child_count() > 0):
		for scene in $SceneManager.get_children():
			print("%s is in the scene root." % scene.name)
			# There should never be more than one scene loaded at one time.
			scene.queue_free()
			print("Scene freed.")
	else:
		print("No scenes found in the scene manager root.")
	
	# Poll loading progress.
	while(true):
		var status: ResourceLoader.ThreadLoadStatus
		var progress: Array[float] = []
		var error = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
		
		if(error == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS):
			var percent: float = progress[0] * 100
			$load_bar._set_value(percent)
		elif(error == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
			var resource: PackedScene = ResourceLoader.load_threaded_get(next_scene_path) as PackedScene
			var new_scene: Node2D = resource.instantiate() as Node2D
			print("New scene %s successfully loaded." % new_scene.name)
			$SceneManager.add_child(new_scene)
			$load_bar.hide()
			_set_state(states.FADEIN)
			return
		else:
			push_error("Error occurred while loading the scene.")
			$load_bar.hide()
			return
		
		await get_tree().process_frame

# Video Functions
func _update_video() -> void:
	DisplayServer.window_set_current_screen(monitor)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	var screen_size: Vector2i = DisplayServer.screen_get_size(monitor)
	var screen_position: Vector2i = DisplayServer.screen_get_position((monitor))
	
	if(fullscreen):
		DisplayServer.window_set_size(BASE_RES)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_size(BASE_RES * current_scale)
		var window_size: Vector2i = DisplayServer.window_get_size()
		var center_position: Vector2i = screen_position + (screen_size - window_size) / 2
		DisplayServer.window_set_position(Vector2i.ZERO)

# Audio Functions
func _update_audio() -> void:
	var music_db: float = -80.0 if mute_on_focus_loss && !has_focus else music_volume
	var sound_db: float = -80.0 if mute_on_focus_loss && !has_focus else sound_volume
	
	AudioServer.set_bus_volume_db(MUSIC_BUS_INDEX, music_db)
	AudioServer.set_bus_volume_db(SOUND_BUS_INDEX, sound_db)

func _play_music(track_name: String, immediate: bool = false) -> void:
	if(!immediate && is_fading_music): return
	
	var path: String = "res://assets/audio/music/" + track_name + ".ogg"
	
	if(!ResourceLoader.exists(path)):
		push_error("Track %s not found at %s!" % [track_name, path])
		return
	
	var stream: AudioStream = ResourceLoader.load(path) as AudioStream
	
	if(immediate || !$CurrentTrack.playing):
		$CurrentTrack.stop()
		$CurrentTrack.stream = stream
		$CurrentTrack.play()
		queued_track = ""
	else:
		queued_track = track_name
		is_fading_music = true;
		if(music_tween): music_tween.kill()
		music_tween = create_tween()
		music_tween.tween_property($CurrentTrack, "volume_db", -80.0, MUSIC_FADE_DURATION)
		music_tween.tween_callback(Callable(self, "_on_music_fade_complete"))

func _stop_music(fade: bool = true) -> void:
	if(!$CurrentTrack.playing): return
	
	if(!fade):
		$CurrentTrack.stop()
		queued_track = ""
		is_fading_music = false
	elif(!is_fading_music):
		is_fading_music = true;
		music_tween = create_tween()
		music_tween.tween_property($CurrentTrack, "volume_db", -80.0, MUSIC_FADE_DURATION)
		music_tween.tween_callback(Callable(self, "_on_music_stop_fade_complete"))

func _on_fade_music_complete() -> void:
	$CurrentTrack.stop()
	if(queued_track != ""):
		_play_music(queued_track)
		queued_track = ""
	is_fading_music = false

func _on_music_stop_fade_complete() -> void:
	$CurrentTrack.stop()
	queued_track = ""
	is_fading_music = false

func _play_sound(sound_name: String) -> void:
	var path: String = "res://assets/audio/sfx/" + sound_name + ".wav"
	
	if(!ResourceLoader.exists(path)):
		push_error("Sound %s not found!" % sound_name)
		return
	
	var stream: AudioStream = ResourceLoader.load(path) as AudioStream
	
	for player in sound_players:
		if(player.stream == stream):
			player.stop()
			if(player.is_inside_tree()): player.play()
			return
	
	var new_player: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(new_player)
	new_player.stream = stream
	new_player.bus = "Sound"
	new_player.play()
	sound_players.append(new_player)
	new_player.connect("finished", Callable(self, "_on_sound_finished"))

func _stop_sound(sound_name: String) -> void:
	var path: String = "res://assets/audio/sfx/" + sound_name + ".wav"
	
	if(!ResourceLoader.exists(path)): return
	
	var stream: AudioStream = ResourceLoader.load(path) as AudioStream
	
	for player in sound_players:
		if(player.stream == stream): player.stop()

func _on_sound_finished():
	for player in sound_players:
		if(!player.playing && player.is_inside_tree()):
			player.queue_free()
			sound_players.erase(player)
