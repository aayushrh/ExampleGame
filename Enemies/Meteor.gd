extends Area2D

var lifetime = 100
var player = null
export(int) var damage = 1

func _process(delta):
	lifetime -= 1
	update()
	if lifetime <= 5:
		$CollisionShape2D.disabled = false
	if lifetime <= 0:
		queue_free()

func _draw():
	var radius = $CollisionShape2D.shape.radius + lifetime
	draw_circle_arc(Vector2(0, 0), radius, 0, 360, Color(255, 255, 255))
	draw_circle(Vector2(0, 0), $CollisionShape2D.shape.radius, Color(255, 0, 0))

func draw_circle_arc(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PoolVector2Array()

	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to-angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	for index_point in range(nb_points):
		draw_line(points_arc[index_point], points_arc[index_point + 1], color)

func _on_Meteor_body_entered(body):
	player = body

func _on_Meteor_body_exited(body):
	player = null
