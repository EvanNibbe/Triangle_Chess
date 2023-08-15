extends Node3D
#important functions for reference elsewhere at the bottom of the script.
var mouse_inside: bool=false
#each player piece needs to have the function
#func can_move_to(Vector3 global_pos)->bool
#which is checked on each triangle after the user has clicked then unclicked the left mouse button in 2 cycles.
var player_pieces: Array[Node3D]=[]
var change_material: GeometryInstance3D=null

var mouse_previously_clicked: bool=false #
var mouse_click_half_cycle_number: int=0 #increment by +1 on each start of click and each start of unclick.
var able_to_be_chosen: bool=false
var is_selected: bool=false
var piece_on_spot: bool=false
var which_piece: Node3D=null
var exists_a_piece_to_move_here: bool=false
var current_time: float=0
var thing_autoloaded: Node=null
# Called when the node enters the scene tree for the first time.
func _ready():
	change_material=$StaticBody3D/MeshInstance3D
	change_material.set_instance_shader_parameter("center_position", $center_triangle.global_position)
	#this is the material that needs to be constantly changed in the process function (each time the player clicks-unclicks the mouse in 2 cycles)
	pass # Replace with function body.
	thing_autoloaded=get_node("/root/piece_selected")
	thing_autoloaded.possible_positions.append($center_triangle.global_position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	current_time+=delta #
	if current_time>3 and current_time<5 and int(current_time+delta)>int(current_time): #avoid this function repeating too many times.
		if not thing_autoloaded.is_black:
			player_pieces=thing_autoloaded.white_player_pieces
		else: #player is black 
			player_pieces=thing_autoloaded.black_player_pieces
	var just_clicked: bool=false
	var get_click: int=Input.get_mouse_button_mask()
	var recheck_movement_options: bool=false
	#var thing_autoloaded: Node=get_node("/root/piece_selected")
	var to_check: Node3D=thing_autoloaded.piece_selected 
	if get_click>0: #any mouse button pressed 
		if not mouse_previously_clicked: #
			var board_place: Vector3=global_position #used just for debugging to know what triangle is being considered.
			mouse_click_half_cycle_number+=1
			mouse_previously_clicked=true
			just_clicked=true
			if mouse_inside:
				if thing_autoloaded.any_piece_selected and piece_on_spot==false:
					print("there has been a piece selected and mouse is inside "+str(name)+" on click, so moving to "+str($center_triangle.global_position))
					thing_autoloaded.move_piece_to($center_triangle.global_position) #this function automatically checks whether this is a legal move.
	if get_click==0:
		if mouse_previously_clicked:
			mouse_click_half_cycle_number+=1
			mouse_previously_clicked=false #
			if mouse_click_half_cycle_number%3==0:
				recheck_movement_options=true
	if int(current_time)%3==2 and int(current_time+delta)>int(current_time): #recheck movement options once every 3 seconds.
		recheck_movement_options=true
	if recheck_movement_options: #
		able_to_be_chosen=false
		#here I put the very costly code for going through every piece to see if it can move to this triangle's position.
		#then I put in the code for filling the parameters in change_material.
		
		if thing_autoloaded.any_piece_selected and to_check.has_method("can_move_to"):
			#change_material.set_shader_parameter("piece_selectable", false) #if a piece is selected, then don't apply this coloration.
			if ($center_triangle.global_position-to_check.global_position).length()>sqrt(3)/3:
				able_to_be_chosen=to_check.can_move_to($center_triangle.global_position)
				change_material.set_instance_shader_parameter("selectable", able_to_be_chosen)
			else:
				able_to_be_chosen=false
				change_material.set_instance_shader_parameter("selectable", able_to_be_chosen) #would be false
		else: #no piece is selected
			piece_on_spot=false #
			for piece in player_pieces:
				if (piece.global_position-$center_triangle.global_position).length()<sqrt(3)/3:
					piece_on_spot=true #
					which_piece=piece
					break #
			change_material.set_instance_shader_parameter("piece_selectable", piece_on_spot)
			if not piece_on_spot:
				#no piece is selected, there exists the possibility that there's a piece such that, if selected, it has a movement option that could reach here
				exists_a_piece_to_move_here=false
				for piece in player_pieces:
					if piece.has_method("can_move_to") and piece.can_move_to($center_triangle.global_position):
						exists_a_piece_to_move_here=true
						break
				change_material.set_instance_shader_parameter("exists_a_piece_to_move_here", exists_a_piece_to_move_here)
			
	if just_clicked and able_to_be_chosen and mouse_inside and (not thing_autoloaded.any_move_to_position):
		
		#thing_autoloaded.any_move_to_position=true
		is_selected=thing_autoloaded.move_piece_to($center_triangle.global_position)
		change_material.set_instance_shader_parameter("is_selected", is_selected)
	#if Input.get_mouse_button_mask()>0 and mouse_inside:
		#print("triangle at "+str(global_position)+" was clicked and mouse is inside.")
	if just_clicked and mouse_inside and piece_on_spot and which_piece.has_method("is_chosen") and which_piece.has_method("unclick") and which_piece.has_method("click"):
		print("triange at "+str(global_position)+" was just clicked and mouse is inside. There is a piece on the spot named "+str(which_piece.name)+" \n")
		if which_piece.is_chosen():
			which_piece.unclick()
		else:
			which_piece.click()
			thing_autoloaded.piece_clicked(which_piece)
			#this gives the changes to the rendering server so that the shader for this triangle should infer that 
			#it needs to be the correct color.
	if exists_a_piece_to_move_here or able_to_be_chosen or piece_on_spot:
		$center_triangle/MeshInstance3D.visible=false #
	else:
		$center_triangle/MeshInstance3D.visible=true #this blocks the piece from being seen.
	pass


func _on_static_body_3d_mouse_entered():
	mouse_inside=true
	

func _on_static_body_3d_mouse_exited():
	mouse_inside=false
	
func can_choose()->bool:
	return able_to_be_chosen

func is_chosen()->bool:
	return is_selected #this means the piece should move towards this spot.

func has_mouse()->bool:
	return mouse_inside
	

func put_piece(piece: Node3D): #the piece put in needs to have func can_move_to(Vector3)->bool
	var already_there: bool=false 
	for i in player_pieces:
		if str(i.name).begins_with(str(piece.name)):
			already_there=true  # each piece must have a unique name
	if not already_there:
		player_pieces.append(piece)
	pass
