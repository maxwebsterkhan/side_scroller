extends Area2D

signal request_respawn(position)

@onready var animation_tree = $AnimationTree
@onready var animation_player = $AnimationPlayer
@onready var reset_timer = $ResetTimer  # Ensure this path is correct

func _ready():
	add_to_group("bear_traps")
	animation_player.connect("animation_finished", Callable(self, "_on_AnimationPlayer_animation_finished"))
	animation_tree.active = true

func _on_body_entered(body):
	if body.is_in_group("Player"):
		animation_tree.set("parameters/conditions/sprung", true)

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "sprung":
		animation_tree.set("parameters/conditions/sprung", false)
		reset_timer.start()  # Start the timer after sprung animation
	if anim_name == "unsprung":
		animation_tree.set("parameters/conditions/unsprung", false)
		animation_tree.set("parameters/conditions/idle", true)

func _on_reset_timer_timeout():
	animation_tree.set("parameters/conditions/unsprung", true)
