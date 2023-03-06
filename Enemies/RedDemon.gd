extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

var rng = RandomNumberGenerator.new()

export(int) var ACCELERATION = 200
export(int) var MAX_SPEED = 100
export(float) var FRICTION = 0.9
export(int) var ROTATIONSPEED = 10
export(int) var KNOCKBACK = 200
export(int) var health = 3

enum{
	WANDER,
	CHASE,
	ATTACK
}

var player = null
var wr = null
var state = WANDER
var spawn_position = Vector2.ZERO
var wander_point = Vector2.ZERO
var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

onready var animation_tree = $AnimationTree
onready var animation_mode = animation_tree.get("parameters/playback")

func _ready():
	$Pivot/Hitbox/CollisionShape2D.disabled = true
	spawn_position = global_position
	wander_point = global_position
	rng.randomize()
	#set the initial variables

func _physics_process(delta):
	rng.randomize()
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	knockback = move_and_slide(knockback)
	#take into account knockback
	if state == WANDER:
		wander(delta)
	elif state == CHASE:
		chase(delta)
	elif state == ATTACK:
		attack(delta)
	#call the correct function based on the state

func attack(delta):
	animation_mode.travel("Attack")
	#Do attack animation

func wander(delta):
	if global_position.distance_to(wander_point) <= 5:
		var offset = Vector2(rng.randi_range(-50, 50), rng.randi_range(-50, 50))
		wander_point = spawn_position + offset
		#find a new wandering point when it reached the previoud one
	else:
		var direction = global_position.direction_to(wander_point)
		animation_tree.set("parameters/Idle/blend_position", direction)
		animation_tree.set("parameters/Run/blend_position", direction)
		animation_tree.set("parameters/Attack/blend_position", direction)
		animation_mode.travel("Run")
		velocity += (direction * ACCELERATION * delta)/2
		velocity.clamped(MAX_SPEED/2)
		velocity *= FRICTION
		velocity = move_and_slide(velocity)
		#move towards the wandering point, with animation

func chase(delta):
	if wr.get_ref():
		var direction = global_position.direction_to(player.global_position)
		direction = direction + Vector2(rng.randi_range(-0.1, 0.1), rng.randi_range(-0.1, 0.1))
		#find direction to the player, with ome offset
		direction = direction.normalized()
		#cut off direciton at the unit circle
		animation_tree.set("parameters/Idle/blend_position", direction)
		animation_tree.set("parameters/Run/blend_position", direction)
		animation_tree.set("parameters/Attack/blend_position", direction)
		animation_mode.travel("Run")
		#Animations moment
		velocity += direction * ACCELERATION * delta
		#add it to velocity
		velocity.clamped(MAX_SPEED)
		velocity *= FRICTION
		#clamp it to max speed, and apply friction
		velocity = move_and_slide(velocity)
		if global_position.distance_to(player.global_position) <= 16:
			state = ATTACK
			#if close enough to the player, attack

func _on_PlayerDetectionZone_body_entered(body):
	player = body
	wr = weakref(player)
	state = CHASE
	#is player entered the detection zone, see it

func _on_PlayerDetectionZone_body_exited(body):
	player = null
	state = WANDER
	#is player exits vision range, let it go

func _on_Hurtbox_area_entered(area):
	health -= area.damage
	knockback = area.knockback_vector * 150
	#if you egt hit knockback is applyed
	$Hurtbox.create_hit_effect()
	$Hurtbox.start_invincibility(0.4)
	#starting invincibility for 0.4 seconds
	if(health <= 0):
		queue_free()
		var enemyDeathEffect = EnemyDeathEffect.instance()
		get_parent().add_child(enemyDeathEffect)
		enemyDeathEffect.global_position = global_position
		#if it dies, add death effect

func animation_finished():
	state = CHASE

func _on_Hurtbox_invincibility_ended():
	$AnimationPlayer2.play("StopInvinc")

func _on_Hurtbox_invincibility_started():
	$AnimationPlayer2.play("StartInvinc")
