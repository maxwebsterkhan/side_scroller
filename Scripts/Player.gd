extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction : Vector2 = Vector2.ZERO
var attack : bool = false
var has_double_jumped : bool = false

@export var speed : float = 100.0
@export var jump_velocity = -150.0

@onready var sprite = $AnimatedSprite2D
@onready var animation_tree = $AnimationTree

var wall_jump_force = Vector2(-3000, -150)  
var is_dashing = false
var dash_speed = 250.0  # Speed of the dash
var dash_duration = 0.2  # How long the dash lasts
var dash_timer = 0  # Timer to track dash duration
var is_clinging_to_wall = false
var wall_slide_speed = 10.0  # The speed at which the player slides down the wall
var cling_direction = 0  # Direction of the wall (1 for right, -1 for left)


func _ready():
	animation_tree.set_active(true)

func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta

	# Wall clinging logic
	is_clinging_to_wall = is_on_wall_only() and not is_on_ceiling()
	if is_clinging_to_wall:
		# Controlled wall slide
		if velocity.y > wall_slide_speed:
			velocity.y = wall_slide_speed
		animation_tree.set("parameters/conditions/is_wall_sliding", true)

		# Wall jump logic
		if Input.is_action_just_pressed("ui_accept"):
			handle_wall_jump()
		
		animation_tree.set("parameters/conditions/is_wall_sliding", true)
	else:
		animation_tree.set("parameters/conditions/is_wall_sliding", false)

	# Dash logic
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			animation_tree.set("parameters/conditions/is_dashing", false)
			# Reset the dash direction to allow normal movement again
			direction.x = Input.get_axis("ui_left", "ui_right")
		else:
			velocity.x = dash_speed * sign(direction.x)  # Apply dash velocity
			move_and_slide()
			return  # Skip the rest of the physics processing ONLY when dashing

	# Check if the character is on the floor and handle jumping
	if is_on_floor_only():
		has_double_jumped = false  # Reset double jump since we're on the ground
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = jump_velocity
			animation_tree.set("parameters/conditions/is_jumping", true)
			animation_tree.set("parameters/conditions/is_falling", false)
		# Reset the landing animation if the character has just landed
		if velocity.y == 0:
			animation_tree.set("parameters/conditions/has_landed", true)
	elif not is_on_wall():
		# Character is in the air
		if Input.is_action_just_pressed("ui_accept") and not has_double_jumped:
			# Perform double jump if it hasn't been done already
			velocity.y = jump_velocity
			has_double_jumped = true
			animation_tree.set("parameters/conditions/is_jumping", true)
		# Check if character is falling
		if velocity.y > 0:
			animation_tree.set("parameters/conditions/is_falling", true)

	# Handle horizontal movement
	if not attack:
		velocity.x = direction.x * speed
	else:
		velocity.x = 0

	if Input.is_action_just_pressed("dash") and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		animation_tree.set("parameters/conditions/is_dashing", true)

	# Move the character
	move_and_slide()

	# Update animation parameters
	update_animations()

func _process(delta):
	direction.x = Input.get_axis("ui_left", "ui_right")
	update_facing_direction()
	
	if direction != Vector2.ZERO and not attack:
		set_running(true)
		update_blend_position()
	else:
		set_running(false)
		
	if Input.is_action_just_pressed("attack"):
		set_attack(true)
		
func set_attack(value = false):
	attack = value
	animation_tree["parameters/conditions/water_quick_attack"] = value
		
func set_running(value):
	animation_tree["parameters/conditions/is_running"] = value
	animation_tree["parameters/conditions/idle"] = not value
	
func update_blend_position():
	animation_tree["parameters/water_quick_attack/blend_position"] = direction
	animation_tree["parameters/idle/blend_position"] = direction
	animation_tree["parameters/run/blend_position"] = direction

func update_facing_direction():
	if direction.x < 0:
		sprite.scale.x = -abs(sprite.scale.x)
	elif direction.x > 0:
		sprite.scale.x = abs(sprite.scale.x)

func update_animations():
	var is_on_ground = is_on_floor()
	var state_machine = animation_tree.get("parameters/playback")
	
	# Set running or idle animation based on whether the character is moving horizontally
	animation_tree.set("parameters/conditions/is_running", direction.x != 0 and is_on_ground)
	animation_tree.set("parameters/conditions/idle", direction.x == 0 and is_on_ground)

	# Set jumping condition if character is moving upwards
	if not is_on_ground and velocity.y < 0:
		animation_tree.set("parameters/conditions/is_jumping", true)
	else:
		animation_tree.set("parameters/conditions/is_jumping", false)

	# Set falling condition if character is in the air and moving downwards
	if not is_on_ground and velocity.y > 0:
		animation_tree.set("parameters/conditions/is_falling", true)
	else:
		animation_tree.set("parameters/conditions/is_falling", false)

	# Check for landing animation
	if is_on_ground:
		# If we just landed, trigger the landing animation
		if state_machine.get_current_node() == "fall":
			animation_tree.set("parameters/conditions/has_landed", true)
		# If the landing animation is finished, reset the has_landed condition
		elif state_machine.get_current_node() != "land":
			animation_tree.set("parameters/conditions/has_landed", false)

func handle_wall_jump():
	var wall_normal = get_wall_normal()
	velocity.y = wall_jump_force.y  # Apply vertical jump force
	velocity.x = -wall_normal.x * abs(wall_jump_force.x)  # Apply horizontal force away from the wall
	is_clinging_to_wall = false  # No longer clinging after the jump

	# Update animation state
	animation_tree.set("parameters/conditions/is_jumping", true)
	animation_tree.set("parameters/conditions/is_wall_sliding", false)

