extends State

class_name GroundState

@export var movement_data : PlayerMovementData

@export var jump_velocity : float = -300.0
@export var air_state : State
@export var landing_state : State
@export var jump_animation : String = "jump_start"
@export var dash_animation : String = "dash"

@onready var dash_timer = $"../../DashTimer"
@onready var coyote_jump_timer = $"../../CoyoteTimer"
@onready var dash_cooldown_timer = $"../../DashCooldownTimer"

var direction : Vector2 = Vector2.ZERO
var has_left_ground = false
var is_dashing : bool = false

func state_process(delta):
	direction = Input.get_vector("left", "right", "up", "down")
	if character.is_on_floor():
		has_left_ground = false
		coyote_jump_timer.stop()
	else:
		if not has_left_ground:
			has_left_ground = true
			coyote_jump_timer.start()

func _on_coyote_timer_timeout():
	if not character.is_on_floor():
		next_state = air_state
	#if character.is_on_floor():
		#next_state = landing_state

func state_input(event : InputEvent):
	if character.is_on_floor() or coyote_jump_timer.time_left > 0.0:
		if Input.is_action_pressed("jump"):
			jump()
	if character.is_on_floor() and not is_dashing:
		if Input.is_action_pressed("dash"):
			dash()

func jump():
	if character.is_on_floor() or coyote_jump_timer.time_left > 0.0:
		if Input.is_action_pressed("jump"):
			character.velocity.y = movement_data.jump_velocity
			coyote_jump_timer.stop()
			next_state = air_state
			playback.travel(jump_animation)

func dash():
	if not is_dashing and dash_cooldown_timer.time_left <= 0.0:
		# Ensure there is horizontal input before dashing
		if direction.x != 0:
			is_dashing = true

			var dash_velocity = direction.x * movement_data.dash_speed
			character.velocity.x = dash_velocity
			playback.travel(dash_animation)
			dash_timer.start()
			dash_cooldown_timer.start()

func _on_dash_timer_timeout():
	is_dashing = false
	character.velocity.x = 0  # Optionally, reset the horizontal velocity after dashing

func _on_dash_cooldown_timer_timeout():
	pass
