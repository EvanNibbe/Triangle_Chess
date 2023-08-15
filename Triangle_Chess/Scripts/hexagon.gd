extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	set_instance_shader_parameter("hex_pos", global_position)
