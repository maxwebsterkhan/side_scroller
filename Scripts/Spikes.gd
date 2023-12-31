extends Area2D

@onready var animation_tree = $AnimationTree
@onready var animation_player = $AnimationPlayer

func _ready():
	add_to_group("Spikes")
	animation_tree.active = true

func _on_body_entered(body):
	if body.is_in_group("Player"):
		pass
