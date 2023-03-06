extends KinematicBody2D

var rng = RandomNumberGenerator.new()

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export(int) var ACCELERATION = 200
export(int) var MAX_SPEED = 100
export(float) var FRICTION = 0.9
export(int) var ROTATIONSPEED = 10
export(int) var DASHSPEED = 10
export(float) var DASHTIME = 0.1
export(float) var DASHCOOLDOWN = 1
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
var hit = false
var dir_to_player = Vector2.ZERO
var can_attack = true

onready var animation_tree = $AnimationTree
onready var animation_mode = animation_tree.get("parameters/playback")

func _ready():
	$AnimationTree.active = true
	$Hitbox/CollisionShape2D.disabled = true
	$Sprite.material.set_shader_param("shader_param/Active", false)
	spawn_position = global_position
	wander_point = global_position
	rng.randomize()

func _physics_process(delta):
	rng.randomize()
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	knockback = move_and_slide(knockback)
	if state == WANDER:
		wander(delta)
	elif state == CHASE:
		chase(delta)
	elif state == ATTACK:
		attack(delta)

func attack(delta):
	if hit:
		move_and_slide(dir_to_player * DASHSPEED)
	else:
		animation_mode.travel("Attack")

func wander(delta):
	if global_position.distance_to(wander_point) <= 5:
		var offset = Vector2(rng.randi_range(-50, 50), rng.randi_range(-50, 50))
		wander_point = spawn_position + offset
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

func chase(delta):
	if wr.get_ref():
		var direction = global_position.direction_to(player.global_position)
		direction = direction + Vector2(rng.randi_range(-0.1, 0.1), rng.randi_range(-0.1, 0.1))
		direction = direction.normalized()
		animation_tree.set("parameters/Idle/blend_position", direction)
		animation_tree.set("parameters/Run/blend_position", direction)
		animation_tree.set("parameters/Attack/blend_position", direction)
		animation_mode.travel("Run")
		velocity += direction * ACCELERATION * delta
		velocity.clamped(MAX_SPEED)
		velocity *= FRICTION
		velocity = move_and_slide(velocity)
		if global_position.distance_to(player.global_position) <= 100 and can_attack:
			state = ATTACK
			dir_to_player = (player.global_position - global_position).normalized()

func _on_PlayerDetectionZone_body_entered(body):
	player = body
	wr = weakref(player)
	state = CHASE

func _on_PlayerDetectionZone_body_exited(body):
	player = null
	state = WANDER

func _on_Hurtbox_area_entered(area):
	health -= area.damage
	knockback = area.knockback_vector * 150
	$Hurtbox.create_hit_effect()
	$Hurtbox.start_invincibility(0.4)
	if(health <= 0):
		queue_free()
		var enemyDeathEffect = EnemyDeathEffect.instance()
		get_parent().add_child(enemyDeathEffect)
		enemyDeathEffect.global_position = global_position

func animation_finished():
	hit = true
	$StopTimer.start(DASHTIME)
	$Hitbox/CollisionShape2D.disabled = false

func _on_StopTImer_timeout():
	state = CHASE
	hit = false
	$Hitbox/CollisionShape2D.disabled = true
	can_attack = false
	$Cooldown.start(DASHCOOLDOWN)

func _on_Hurtbox_invincibility_ended():
	$Invincibility.play("StopInvinc")

func _on_Hurtbox_invincibility_started():
	$Invincibility.play("StartInvinc")

func _on_Cooldown_timeout():
	can_attack = true
