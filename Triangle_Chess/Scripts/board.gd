extends Node3D

var hex_piece: PackedScene=preload("res://Assets/hexagon.tscn")
var hex_list: Array=[]
# Called when the node enters the scene tree for the first time.
func _ready():
	#var num_rotations: int=0 #there are 5 total rotations of hexes around the first hex in order to build the board.
	#while num_rotations<5:
	#	num_rotations+=1
		#we start with the hexagon at (0, 0, -4*sqrt(3)/2)
	
	var thing_autoloaded: Node=get_node("/root/piece_selected") #
	thing_autoloaded.white_player_pieces.append_array([$king_white, $spiral_rook, $spiral_rook2, $knight, $knight2, $bishop, $bishop2, $bishop9, $bishop10, $bishop8, $pawn, $pawn2, $pawn3, $pawn4, $pawn5, $pawn6, $pawn7, $pawn21, $pawn22, $pawn23, $pawn24, $pawn25, $pawn26, $rook, $rook2])
	thing_autoloaded.black_player_pieces.append_array([$king_black, $spiral_rook4, $spiral_rook3, $knight3, $knight4, $bishop3, $bishop4, $bishop5, $bishop6, $bishop7, $pawn8, $pawn9, $pawn10, $pawn11, $pawn12, $pawn13, $pawn14, $pawn15, $pawn16, $pawn17, $pawn18, $pawn19, $pawn20, $rook3, $rook4])
	#if $white_player_camera.current:
	#	thing_autoloaded.is_black=false
	#elif $black_player_camera.current:
	#	thing_autoloaded.is_black=true #
	#The above lines of code were based on the assumption that the 
	#way the player color could be chosen is to choose which camera is made current
	#that assumption is wrong for my actual players, who need to start in 
	#a separate 2D "main menu" scene, whose main ability to save information for use in the 
	#next scene is to save it to the 
	#thing_autoloaded
	#therefore, the thing_autoloaded script needs to take ultimate authority for 
	#deciding the color of the pieces.
	if thing_autoloaded.is_black==true:
		$black_player_camera.make_current()
	elif thing_autoloaded.is_black==false:
		$white_player_camera.make_current()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
