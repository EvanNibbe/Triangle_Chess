extends Camera3D

var thing_autoloaded: Node=null
var start_pos: Vector3=Vector3()
# Called when the node enters the scene tree for the first time.
func _ready():
	thing_autoloaded=get_node("/root/piece_selected") #
	start_pos=global_position
	pass # Replace with function body.

var pressa: float=0
var pressd: float=0
var pressf: float=0
var presss: float=0
var pressw: float=0
var press_sp: float=0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if Input.is_key_pressed(KEY_W):
		pressw+=delta
		global_translate(Vector3(0, 0, -delta*pressw-delta))
	elif Input.is_key_pressed(KEY_S):
		presss+=delta
		global_translate(Vector3(0, 0, delta*presss+delta))
	else:
		presss=0
		pressw=0
	if Input.is_key_pressed(KEY_A):
		pressa+=delta
		global_translate(Vector3(-delta*pressa-delta, 0, 0))
	elif Input.is_key_pressed(KEY_D):
		pressd+=delta
		global_translate(Vector3(delta*pressd+delta, 0, 0))
	else:
		pressa=0
		pressd=0
	#orthographic projection can make it seem as though going up and down doesn't do anything, 
	#but if these changes are allowed to occur in the background while a player is pressing for a long time
	#then, when the player realizes they need to be in perspective mode and switches, then the player will suddenly see
	#their camera as being ridiculously far away or ridiculously close.
	if Input.is_key_pressed(KEY_SPACE) and not get_projection()==Camera3D.PROJECTION_ORTHOGONAL:
		press_sp+=delta
		global_translate(Vector3(0, delta*press_sp+delta, 0))
	elif Input.is_key_pressed(KEY_F) and not get_projection()==Camera3D.PROJECTION_ORTHOGONAL and global_position.y>3.5 and thing_autoloaded.any_piece_selected:
		#established by ready function.
		pressf+=delta
		global_translate((thing_autoloaded.piece_selected.global_position-global_position)*delta*(pressf+1))
	else:
		press_sp=0
		pressf=0
	
	#switch between orthographic projection and perspective projection
	if Input.is_key_pressed(KEY_P):
		set_perspective(60, 0.45, 1000)
	elif Input.is_key_pressed(KEY_O):
		set_orthogonal(38.3, .45, 1000)
		global_translate(start_pos-global_position) #so that the camera is in the proper position to gain the full benefit of an orthographic projection.
	pass
