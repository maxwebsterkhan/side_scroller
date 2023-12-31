extends CharacterBody2D

@export var movement_data : PlayerMovementData
@export var speed : float = 200.0

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var state_machine : CharacterStateMachine = $CharacterStateMachine

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction : Vector2 = Vector2.ZERO

func _ready():
	animation_tree.active = true

func _physics_process(delta):
	apply_gravity(delta)
	direction = Input.get_vector("left", "right", "up", "down")

	var is_air_state = state_machine.current_state is AirState
	var is_ground_state = state_machine.current_state is GroundState
	
	var is_wall_jumping = is_air_state && state_machine.current_state.just_wall_jumped
	var is_dashing = is_ground_state && state_machine.current_state.is_dashing
	var is_air_dashing = is_air_state && state_machine.current_state.is_dashing
	
	if not is_wall_jumping and not is_dashing and not is_air_dashing:
		# Normal movement handling
		if direction.x != 0 && state_machine.check_if_can_move():
			velocity.x = direction.x * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

	# Always perform the move_and_slide regardless of the state
	move_and_slide()
	update_animation_parameters()
	update_facing_direction(velocity.x)
	
func update_animation_parameters():
	animation_tree.set("parameters/Move/blend_position", direction.x)

func update_facing_direction(velocity_x):
	if velocity_x > 0:
		sprite.scale.x = abs(sprite.scale.x)
	elif velocity_x < 0:
		sprite.scale.x = -abs(sprite.scale.x)
		
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * movement_data.gravity_scale * delta
