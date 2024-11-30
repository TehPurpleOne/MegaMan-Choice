extends Node2D

var scenes : Array[String] = [ # This is a list of game scenes that will be loaded into the Scene Manager.
	"res://scenes/game/demooptions.tscn",
	"res://scenes/game/gameworld.tscn"
]

var game_res: Vector2 = Vector2(384, 224) #Storing this for later use. May not use at all since there's no wallpaper support.
var window_scale: int = 1 : set = resize_window
var max_win_scale: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_scene(1) # Load the initial scene. For now, it'll be the options screen.
	window_scale = 3

func load_scene(index: int) -> void:
	# This function will unload any child scenes for the Scene Manager and load a new one.
	var scene_manager = $SceneManager
	var anim = $AnimationPlayer
	
	for child in scene_manager.get_children(): ## Free all current scenes loaded.
		child.queue_free()
	
	print("All previous scenes unloaded.")
	
	# Load the new scene.
	var scene = load(scenes[index])
	var result = scene.instantiate()
	scene_manager.add_child(result)
	anim.play("FADE")
	
	print("New scene ",result.name," loaded.")

func on_fade_done(anim_name: StringName) -> void:
	pass # Replace with function body.

func resize_window(value: int) -> void:
	# First, determine the maximum window scale.
	for i in range(DisplayServer.screen_get_size(-1).y / game_res.y):
		max_win_scale = i + 1
	
	# Increment max scale once more. This value will denote Full Screen mode.
	max_win_scale += 1
	
	# Clamp the value to prevent errors.
	value = clamp(value, 1, max_win_scale)
	if value != window_scale:
		window_scale = value
	else:
		return
		
	var window = get_window()
	window.mode = Window.MODE_WINDOWED
	
	match window_scale:
		max_win_scale:
			window.size = game_res
			window.mode = Window.MODE_FULLSCREEN
		_:
			window.size = game_res * window_scale
			window.move_to_center()
