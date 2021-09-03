extends AnimatedSprite
var show := false
func _on_Timer_timeout(): visible = show && !visible
func set_and_show(anim: String):
	animation = anim
	show = true
func hide(): show = false
