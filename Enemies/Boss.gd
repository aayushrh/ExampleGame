extends KinematicBody2D

var rng = RandomNumberGenerator.new()

export(int) var ACCELERATION = 200
export(int) var MAX_SPEED = 100
export(float) var FRICTION = 0.9
export(int) var ROTATIONSPEED = 10
export(int) var health = 20

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
var phase = 1
var can_turn = true
var invinc = false
var flying = false
var can_fly = true

onready var Meteor = preload("res://Enemies//Meteor.tscn")

func _ready():
	$AnimatedSprite.connect("animation_finished", self, "animation_finished")
	spawn_position = global_position
	wander_point = global_position
	rng.randomize()

func _physics_process(delta):
	if health <= 10 and phase == 1:
		phase = 2
		state = CHASE
	if flying:
		if (rng.randi_range(0, 100) == 1):
			var offset = Vector2(rng.randi_range(-100, 100), rng.randi_range(-100, 100))
			var meteor = Meteor.instance()
			meteor.global_position = player.global_position + offset
			get_tree().current_scene.add_child(meteor)
	rng.randomize()
	if state == WANDER:
		wander(delta)
	elif state == CHASE:
		chase(delta)
	elif state == ATTACK:
		attack(delta)

func attack(delta):
	if phase == 1:
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
		if phase == 1:
			if global_position.distance_to(player.global_position) <= 700 and can_attack:
				state = ATTACK
				$AnimatedSprite.play("Attack")
				$Line2D.visible = true
		elif phase == 2:
			if can_fly:
				state = ATTACK
				$Hurtbox/CollisionShape2D.disabled = true
				$CollisionShape2D.disabled = true
				flying = true
				$FlyTimer.start(5)
				visible = false

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
	if !invinc:
		health -= 1
		invinc = true
		$InvincibilityTimer.start(0.5)
		if health <= 0:
			queue_free()
		else:
			$CanvasLayer/UI._update_health(health)

func animation_finished():
	if state == ATTACK and phase == 1:
		$AudioStreamPlayer2D.play(1)
		can_turn = false
		$WaitTimer.start(0.5)

func _on_StopTimer_timeout():
	$AudioStreamPlayer2D.stop()
	$Line2D.visible = false
	state = CHASE
	$LaserBeam2D.set_is_casting(false)
	can_attack = false
	$ReloadTimer.start(1)
	$AnimatedSprite.play("Idle")

func _on_ReloadTimer_timeout():
	can_attack = true

func _on_WaitTimer_timeout():
	$LaserBeam2D.set_is_casting(true)
	$StopTimer.start(1)

func _on_InvincibilityTimer_timeout():
	invinc = false

func _on_FlyTimer_timeout():
	visible = true
	flying = false
	$Hurtbox/CollisionShape2D.disabled = false
	$CollisionShape2D.disabled = false
	state = CHASE
	can_fly = false
	$FlyWaitTimer.start(3)

func _on_FlyWaitTimer_timeout():
	can_fly = true
