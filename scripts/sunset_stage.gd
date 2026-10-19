extends Node2D
## Side-view stage: spawns the side-view character picked on the title screen.

## Set this to play a specific character when you run this scene directly (F6).
@export_enum("sky_mage", "heroine", "night_thief") var test_character: String = ""


func _ready() -> void:
	var key: String = test_character if test_character != "" else Game.side_character
	var player: Node2D = load(Game.SIDEVIEW[key]).instantiate()
	player.global_position = $PlayerSpawn.global_position
	add_child(player)
