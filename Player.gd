extends KinematicBody

export var speed = 20
export var h_acceleration = 6
onready var air_acceleration = 1
export var normal_acceleration = 6
onready var gravity = 40
onready var jump = 25

onready var mouse_sensitivity = 0.1
onready var direction = Vector3()
onready var h_velocity = Vector3()
onready var movement = Vector3()
onready var gravity_vec = Vector3()

onready var fdir = Vector3()
onready var hdir = Vector3()

onready var y_rotation = 0
onready var z_rotation = 0

func _input(event):
	if $Head/Camera.current == true:
		fdir = transform.basis.z * (Input.get_action_strength("forward") - Input.get_action_strength("backward"))
		hdir = transform.basis.x * (Input.get_action_strength("left") - Input.get_action_strength("right"))

		if event is InputEventMouseMotion:
			y_rotation = -event.relative.x

		if Input.is_action_just_pressed("action_mouse_escape"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	# controls movement for player view
	if $Head/Camera.current == true:
		direction = Vector3()

		if not is_on_floor():
			gravity_vec += Vector3.DOWN * gravity * delta
			h_acceleration = air_acceleration
		elif is_on_floor():
			gravity_vec = -get_floor_normal() * gravity
			h_acceleration = normal_acceleration
	#		gravity_vec.y = 0
		else:
			gravity_vec = -get_floor_normal()
			h_acceleration = normal_acceleration
#
		if Input.is_action_just_pressed("jump") and is_on_floor():
			gravity_vec = Vector3.UP * jump

		if Input.is_action_pressed("forward"):
			direction += transform.basis.z
		elif Input.is_action_pressed("backward"):
			direction -= transform.basis.z
		if Input.is_action_pressed("left"):
			direction += transform.basis.x
		elif Input.is_action_pressed("right"):
			direction -= transform.basis.x

		direction = direction.normalized()
		h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * delta)
		movement.z = h_velocity.z + gravity_vec.z
		movement.x = h_velocity.x + gravity_vec.x
		movement.y = gravity_vec.y

		var velocity
		if abs(movement.x) > abs(movement.z):
			velocity = abs(movement.x) + 1
		else:
			velocity = abs(movement.z) + 1

		var velocity_proportion = clamp(velocity / speed, 0.1, 1)

		var _discard = move_and_slide(movement, Vector3.UP)
		
		rotate_y(deg2rad(y_rotation * mouse_sensitivity))

		y_rotation = 0
	
