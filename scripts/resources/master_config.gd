extends Resource

class_name MasterConfig

# Control values
@export var input_map_default: Dictionary = {}
@export var input_map: Dictionary = {}

# Video values
@export var fullscreen: bool = false
@export var monitor: int = 0
@export var scale: int = 0

# Audio values
@export_range(-80.0, 0.0) var music_volume: float = 0.0
@export_range(-80.0, 0.0) var sound_volume: float = 0.0
@export var charge_fade: bool = false
@export var mute_on_focus_loss: bool = false
