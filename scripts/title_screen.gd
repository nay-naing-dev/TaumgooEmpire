extends Control
## Title screen over the living Yangon harbour.

@onready var td_pick: OptionButton = %TopdownPick
@onready var sv_pick: OptionButton = %SidePick


func _ready() -> void:
	for key in Game.TOPDOWN.keys():
		td_pick.add_item(key.capitalize())
	for key in Game.SIDEVIEW.keys():
		sv_pick.add_item(key.capitalize())
	td_pick.select(Game.TOPDOWN.keys().find(Game.topdown_character))
	sv_pick.select(Game.SIDEVIEW.keys().find(Game.side_character))
	%ExploreButton.pressed.connect(_on_explore)
	%StageButton.pressed.connect(_on_stage)
	%ExploreButton.grab_focus()
	var tw := create_tween().set_loops()
	tw.tween_property(%Hint, "modulate:a", 0.35, 1.2)
	tw.tween_property(%Hint, "modulate:a", 1.0, 1.2)


func _on_explore() -> void:
	Game.topdown_character = Game.TOPDOWN.keys()[td_pick.selected]
	Game.go(Game.WORLD)


func _on_stage() -> void:
	Game.side_character = Game.SIDEVIEW.keys()[sv_pick.selected]
	Game.go(Game.STAGE)
