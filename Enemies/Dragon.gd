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
var can_attack = true
var can_turn = true
var knockback = Vector2.ZERO

func _ready():
	$AnimatedSprite.connect("animation_finished", self, "animation_finished")
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
	if can_turn:
		rotateToTarget(self, player.global_position , delta)
		$Line2D.points = [Vector2(0, 0), player.global_position - global_position]
		$Line2D.rotation_degrees = -rotation_degrees

func wander(delta):
	if global_position.distance_to(wander_point) <= 5:
		var offset = Vector2(rng.randi_range(-50, 50), rng.randi_range(-50, 50))
		wander_point = spawn_position + offset
	else:
		var direction = global_position.direction_to(wander_point)
		rotateToTarget(self, wander_point, delta)
		velocity += (direction * ACCELERATION * delta)/2
		velocity.clamped(MAX_SPEED/2)
		velocity *= FRICTION
		velocity = move_and_slide(velocity)

func chase(delta):
	if wr.get_ref() and player != null:
		$Line2D.visible = false
		var direction = global_position.direction_to(player.global_position)
		direction = direction + Vector2(rng.randi_range(-0.1, 0.1), rng.randi_range(-0.1, 0.1))
		direction = direction.normalized()
		rotateToTarget(self, player.global_position , delta)
		velocity += direction * ACCELERATION * delta
		velocity.clamped(MAX_SPEED)
		velocity *= FRICTION
		velocity = move_and_slide(velocity)
		if global_position.distance_to(player.global_position) <= 400 and can_attack:
			state = ATTACK
			$AnimatedSprite.play("Attack")
			$Line2D.visible = true

func rotateToTarget(thing, target, delta):
	var direction = (target - global_position)
	var angleTo = 0
	angleTo = thing.transform.x.angle_to(direction)
	thing.rotate(sign(angleTo) * min(delta * ROTATIONSPEED, abs(angleTo)))

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
	if state == ATTACK:
		$AudioStreamPlayer2D.play(1)
		$WaitTimer.start(0.5)
		can_turn = false

func _on_StopTimer_timeout():
	$AudioStreamPlayer2D.stop()
	can_turn = true
	state = CHASE
	$LaserBeam2D.set_is_casting(false)
	can_attack = false
	$ReloadTimer.start(1)
	$AnimatedSprite.play("Idle")

func _on_ReloadTimer_timeout():
	can_attack = true

func _on_WaitTimer_timeout():
	$Line2D.visible = false
	$LaserBeam2D.set_is_casting(true)
	$StopTimer.start(1)

func _on_Hurtbox_invincibility_started():
	$Invincibility.play("StartInvinc")

func _on_Hurtbox_invincibility_ended():
	$Invincibility.play("StopInvinc")
