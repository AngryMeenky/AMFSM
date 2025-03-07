@tool
extends SubViewportContainer

@onready var subview := $SubViewport


func _on_resized() -> void:
	prints("Resized", size)
	#($SubViewport if subview == null else subview).size = size
