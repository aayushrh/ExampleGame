extends Control

func _update_health(health):
	$ColorRect.rect_size.x = 61/4 * (health)/5
