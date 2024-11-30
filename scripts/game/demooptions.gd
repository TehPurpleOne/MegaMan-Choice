extends Node2D

var menu_pos: int = 0;
var lines: Array[String] = [
	"    WINDOW SCALE:",
	"    FULLSCREEN SCALE:",
	"    LEVEL ID:"
]

func _ready() -> void:
	update_menu()

func _physics_process(delta: float) -> void:
	pass

func update_menu() -> void:
	$Options.text = ""
	$Options.text += "MEGAMAN CHOICE\n\n\n"
	
	for i in range(lines.size()):
		if menu_pos == i: # Highlight the current selection. Grey out the rest.
			$Options.text += "[color=white]"
		else:
			$Options.text += "[color=gray]"
		
		$Options.text += lines[i]
		$Options.text += "[/color]\n"
