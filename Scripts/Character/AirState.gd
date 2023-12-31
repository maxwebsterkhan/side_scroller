extends State

class_name AirState

@export var movement_data : PlayerMovementData

@export var landing_state : State
@export var jump_start_transition_animation: String = "jump_transition"
@export var jump_start_fall_animation: String = "jump_start_fall"
@export var landing_animation : String = "jump_end"
@export var wall_slide_animation : String = "wall_slide"
@export var dash_animation : String = "dash"

@onready var wall_jump_timer = $"../../WallJumpTimer"
@onready var dash_timer = $"../../DashTimer"
@onready var dash_cooldown_timer = $"../../DashCooldownTimer"
@onready var coyote_time_timer = $"../../CoyoteTimer"

var direction : Vector2 = Vector2.ZERO
var is_dashing : bool = false
var air_jump = false
var just_wall_jumped = false
var was_wall_normal = Vector2.ZERO
var has_just_switched = false 
var has_double_jumped = false

func state_process(delta):
	var input_axis = Input.get_axis("left", "right")
	direction = Input.get_vector("left", "right", "up", "down")
	handle_acceleration(input_axis, delta)
	handle_air_acceleration(input_axis, delta)
	apply_friction(input_axis, delta)
	apply_air_resistance(input_axis, delta)

	if character.is_on_floor():
		next_state = landing_state
	else:
		if character.is_on_wall_only():
			apply_wall_traction(delta)
		update_air_animations()

func apply_wall_traction(delta):
	var wall_direction = -character.get_wall_normal().x
	var input_direction = Input.get_axis("left", "right")

	if wall_direction != 0 and sign(wall_direction) == sign(input_direction):
		# Significantly increase the wall traction strength for testing
		playback.travel(wall_slide_animation)
		var wall_traction_strength = 100000  # Adjust this value as needed

		if character.velocity.y > 0:
			character.velocity.y -= wall_traction_strength * delta
			# Ensure the velocity doesn't become negative (moving upwards)
			character.velocity.y = max(character.velocity.y, 0)
			
func update_air_animations():
	if is_dashing:
		playback.travel(dash_animation)
	elif character.is_on_wall_only():
		if character.velocity.y > 0:
			playback.travel(wall_slide_animation)
		elif just_wall_jumped:
			playback.travel(jump_start_transition_animation)
	else:
		if character.velocity.y < 0 and not has_just_switched:
			playback.travel(jump_start_transition_animation)
			has_just_switched = true
		elif character.velocity.y >= 0 and has_just_switched:
			playback.travel(jump_start_fall_animation)
			has_just_switched = false

func on_enter():
	has_just_switched = false

func state_input(event: InputEvent):
	if event.is_action_pressed("jump") and not has_double_jumped:
		double_jump()
	if event.is_action_pressed("jump") and (character.is_on_wall_only() or coyote_time_timer.time_left > 0.0):
		wall_jump()
	if event.is_action_pressed("dash") and !character.is_on_floor() and not is_dashing:
		dash()

func on_exit():
	just_wall_jumped = false
	if next_state == landing_state:
		playback.travel(landing_animation)
		has_double_jumped = false

func double_jump():
	if not character.is_on_floor() and not has_double_jumped:
		character.velocity.y = movement_data.jump_velocity
		has_double_jumped = true

func wall_jump():
	var wall_normal = character.get_wall_normal()
	if wall_jump_timer.time_left > 0.0:
		wall_normal = was_wall_normal
	character.velocity.x = wall_normal.x * movement_data.speed
	character.velocity.y = movement_data.jump_velocity
	just_wall_jumped = true
	wall_jump_timer.start()
	coyote_time_timer.stop()  # Stop coyote time after jumping

func handle_acceleration(input_axis, delta):
	if not character.is_on_floor(): return
	if input_axis != 0:
		character.velocity.x = move_toward(character.velocity.x, movement_data.speed * input_axis, movement_data.acceleration * delta)

func handle_air_acceleration(input_axis, delta):
	if character.is_on_floor(): return
	if input_axis != 0:
		character.velocity.x  = move_toward(character.velocity.x, movement_data.speed * input_axis, movement_data.air_acceleration * delta)

func apply_friction(input_axis, delta):
	if input_axis == 0 and character.is_on_floor():
		character.velocity.x = move_toward(character.velocity.x, 0, movement_data.friction * delta)

func apply_air_resistance(input_axis, delta):
	if input_axis == 0 and not character.is_on_floor():
		character.velocity.x = move_toward(character.velocity.x, 0, movement_data.air_resistance * delta)

func _on_wall_jump_timer_timeout():
	just_wall_jumped = false
	wall_jump_timer.stop()

func dash():
	if not is_dashing and dash_cooldown_timer.time_left <= 0.0:
		if direction.x != 0:
			is_dashing = true
			var dash_velocity = direction.x * movement_data.dash_speed
			character.velocity.x = dash_velocity
			dash_timer.start()
			dash_cooldown_timer.start()

func _on_dash_timer_timeout():
	is_dashing = false
	character.velocity.x = 0  # Optionally, reset the horizontal velocity after dashing

func _on_coyote_timer_timeout():
	pass # Replace with function body.
