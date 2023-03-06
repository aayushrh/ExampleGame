extends Node

export(int) var max_health = 1 setget set_max_health
var health = max_health setget set_health

signal no_health
signal health_changed(value)
signal max_health_changed(value)

func set_max_health(value):
	max_health = value
	self.health = min(health, max_health)
	emit_signal("max_health_changed", max_health)
	#puts out a signal that max health changed

func set_health(value):
	health = value
	emit_signal("health_changed", health)
	#emits a signal that says health changed
	if health <= 0:
		emit_signal("no_health")
		#emits a signal that player died

func _ready():
	self.health = max_health
	#initially sets player's health to max
