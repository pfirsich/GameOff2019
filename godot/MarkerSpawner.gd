extends Node

const colors = {
    "r": Color(1, 0, 0),
    "g": Color(0, 1, 0),
    "b": Color(0, 0, 1),
    "y": Color(1, 1, 0),
    "p": Color(1, 0, 1),
}

var markerScene = preload("res://Marker.tscn")

func mark(position : Vector3, color):
    if color is String:
        if color in colors:
            color = colors[color]
        else:
            color = Color(color)
    var marker = markerScene.instance()
    marker.set_translation(position)
    var mat = marker.get_surface_material(0).duplicate()
    mat.albedo_color = color
    mat.albedo_color.a = 0.4
    marker.set_surface_material(0, mat)
    add_child(marker)

func _process(delta):
    if Input.is_action_just_pressed("clearmarkers"):
        for marker in get_tree().get_nodes_in_group("marker"):
            marker.queue_free()
