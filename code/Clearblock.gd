extends Node2D
onready var collider := $StaticBody2D
onready var tween := $Tween
onready var limit_text := $Label
var depth := 100

func increase_limit():
	depth += 100
	limit_text.text = "%sm" % depth
