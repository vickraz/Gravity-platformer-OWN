extends CharacterBody2D

enum {IDLE, WALK, AIR, EDGE}

const SPEED = 300.0
const ACC = 1500.0 
const JUMP_VELOCITY = 650.0
const GRAVITY = 1250
const EDGE_SPEED = 150


@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

@onready var left_ray: RayCast2D = $LeftRay
@onready var right_ray: RayCast2D = $RightRay

var state: int = AIR

var can_rotate = true
#var rotational_direction = "right"


func _physics_process(delta: float) -> void:
	print(state)
	match state:
		IDLE:
			_idle_state(delta)
		WALK:
			_walk_state(delta)
		AIR:
			_air_state(delta)


################ GENERAL HELP FUNCTIONS #####################
func _update_direction(input_x: float) -> void:
	if input_x > 0:
		sprite.flip_h = false
	elif input_x < 0:
		sprite.flip_h = true

func _movement(input_x: float, delta: float) -> void:
	if up_direction.is_equal_approx(Vector2.UP):
		if input_x != 0:
			velocity.x = move_toward(velocity.x, input_x*SPEED, 2*ACC*delta)
		else:
			velocity.x = move_toward(velocity.x, 0, ACC*delta)
		
		#ADDING GRAVITY
		velocity.y +=  GRAVITY * delta
	elif up_direction.is_equal_approx(Vector2.DOWN):
		if input_x != 0:
			velocity.x = move_toward(velocity.x, -input_x*SPEED, 2*ACC*delta)
		else:
			velocity.x = move_toward(velocity.x, 0, ACC*delta)
		
		#ADDING GRAVITY
		velocity.y += -sign(up_direction.y)* GRAVITY * delta
	elif up_direction.is_equal_approx(Vector2.RIGHT):
		if input_x != 0:
			velocity.y = move_toward(velocity.y, input_x*SPEED, 2*ACC*delta)
		else:
			velocity.y = move_toward(velocity.y, 0, ACC*delta)
		
		#ADDING GRAVITY
		velocity.x += -sign(up_direction.x) * GRAVITY * delta
	elif up_direction.is_equal_approx(Vector2.LEFT):
		if input_x != 0:
			velocity.y = move_toward(velocity.y, -input_x*SPEED, 2*ACC*delta)
		else:
			velocity.y = move_toward(velocity.y, 0, ACC*delta)
		
		#ADDING GRAVITY
		velocity.x += -sign(up_direction.x) * GRAVITY * delta
	
	#MOVING THE PLAYER
	move_and_slide()

func _rotate_left():
	if up_direction.is_equal_approx(Vector2.UP):
		velocity.x = -EDGE_SPEED 
		velocity.y = SPEED
	elif up_direction.is_equal_approx(Vector2.DOWN):
		velocity.x = EDGE_SPEED
		velocity.y = -SPEED - 200
	elif up_direction.is_equal_approx(Vector2.RIGHT):
		velocity.y = -EDGE_SPEED
		velocity.x = -SPEED - 200
	elif up_direction.is_equal_approx(Vector2.LEFT):
		velocity.y = EDGE_SPEED
		velocity.x = SPEED + 200
	up_direction = up_direction.rotated(-PI/2)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees", rotation_degrees - 90, 0.1)
	can_rotate = false
	$RotationCooldown.start()
	
	
func _rotate_right():
	if up_direction.is_equal_approx(Vector2.UP):
		velocity.x = EDGE_SPEED
		velocity.y = SPEED
	elif up_direction.is_equal_approx(Vector2.DOWN):
		velocity.x = -EDGE_SPEED
		velocity.y = -SPEED
	elif up_direction.is_equal_approx(Vector2.RIGHT):
		velocity.y = EDGE_SPEED
		velocity.x = -SPEED
	elif up_direction.is_equal_approx(Vector2.LEFT):
		velocity.y = -EDGE_SPEED
		velocity.x = SPEED
	up_direction = up_direction.rotated(PI/2)
	#rotation_degrees += 90
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees", rotation_degrees + 90, 0.1)
	can_rotate = false
	$RotationCooldown.start()

################# STATE FUNCTIONS ###########################
func _idle_state(delta: float) -> void:
	if Input.is_action_just_pressed("Jump"):
		_enter_air_state()
	var input_x = Input.get_axis("ui_left", "ui_right")
	_update_direction(input_x)
	
	#CHECK FOR EDGES
	if not left_ray.is_colliding() and right_ray.is_colliding():
		if can_rotate and sign(input_x) == -1:#is_equal_approx(up_direction.rotated(-PI/2).angle(), velocity.angle()):
			_rotate_left()
	elif left_ray.is_colliding() and not right_ray.is_colliding():
		if can_rotate and sign(input_x) == 1:#is_equal_approx(up_direction.rotated(PI/2).angle(), velocity.angle()):
			_rotate_right()
	
	_movement(input_x, delta)
	
	if not is_on_floor():
		_enter_air_state(false)
	elif velocity.length() != 0:
		_enter_walk_state()

func _walk_state(delta: float) -> void:
	if Input.is_action_just_pressed("Jump"):
		_enter_air_state()
	var input_x = Input.get_axis("ui_left", "ui_right")
	_update_direction(input_x)
	
	
	_movement(input_x, delta)
	#CHECK FOR EDGES
	if not left_ray.is_colliding() and right_ray.is_colliding():
		if can_rotate and is_equal_approx(up_direction.rotated(-PI/2).angle(), velocity.angle()):
			_rotate_left()
	elif left_ray.is_colliding() and not right_ray.is_colliding():
		if can_rotate and is_equal_approx(up_direction.rotated(PI/2).angle(), velocity.angle()):
			_rotate_right()
	if velocity.x == 0:
		_enter_idle_state()

func _air_state(delta: float):
	var input_x = Input.get_axis("ui_left", "ui_right")
	_update_direction(input_x)
	_movement(input_x, delta)
	
	if is_on_floor() and velocity.x != 0:
		_enter_walk_state()
	elif is_on_floor():
		_enter_idle_state()


############### ENTER STATES ############################
func _enter_air_state(jump = true) ->void:
	state = AIR
	if jump:
		velocity += up_direction * JUMP_VELOCITY
	anim.play("Jump")

func _enter_walk_state() -> void:
	state = WALK
	anim.play("Walk")

func _enter_idle_state():
	state = IDLE
	anim.play("Idle")
	

################## SIGNALS ###############################
func _on_rotation_cooldown_timeout() -> void:
	can_rotate = true
