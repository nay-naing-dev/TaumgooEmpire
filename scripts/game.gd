extends Node
## Autoload "Game": remembers which character you picked and switches scenes.
## Press Esc anywhere to go back to the title screen.

const TOPDOWN := {
	"swordsman": "res://characters/topdown/swordsman/swordsman.tscn",
	"gunslinger": "res://characters/topdown/gunslinger/gunslinger.tscn",
	"burmese_man": "res://characters/topdown/burmese_man/burmese_man.tscn",
	"sky_mage": "res://characters/topdown/sky_mage/sky_mage_topdown.tscn",
}
const SIDEVIEW := {
	"sky_mage": "res://characters/sideview/sky_mage/sky_mage.tscn",
	"heroine": "res://characters/sideview/heroine/heroine.tscn",
	"night_thief": "res://characters/sideview/night_thief/night_thief.tscn",
}
const TITLE := "res://scenes/title/title_screen.tscn"
const WORLD := "res://scenes/world/taungoo_world.tscn"
const STAGE := "res://scenes/stages/sunset_stage.tscn"

var topdown_character := "swordsman"
var side_character := "sky_mage"


func go(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and get_tree().current_scene \
			and get_tree().current_scene.scene_file_path != TITLE:
		go(TITLE)
