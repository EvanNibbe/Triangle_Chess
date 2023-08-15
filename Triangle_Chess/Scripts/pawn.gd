extends StaticBody3D

var current_time: float=0
var is_clicked_v: bool=false #
var when_clicked_v: float=-10
var is_black_v: bool=false
var has_improved: bool=false #once a pawn reaches the opposite end (following the z axis) from where it started, and reaches either z<=-9*sqrt(3) or z>=9*sqrt(3)
	#then it gains the power to move to any spot within 2*sqrt(5) of its current location.
var start_pos: Vector3=Vector3()
var all_hashed_positions: Dictionary={}
var time_of_check: float=-1


var thing_autoloaded: Node=null

# Called when the node enters the scene tree for the first time.
func _ready():
	thing_autoloaded=get_node("/root/piece_selected")
	if global_position.z<0:
		$MeshInstance3D.set_instance_shader_parameter("black", true)
		is_black_v=true #black always starts on the -z side.
	pass # Replace with function body.

var dead: bool=false
func hash_pos(global_pos: Vector3, self_capture: bool=false)->int:
	var result: int=0
	if not dead:
		#only counting things that are outside the dead space.
		result+=int((global_pos.x+thing_autoloaded.minX)*(thing_autoloaded.maxZ-thing_autoloaded.minZ)+global_pos.z-thing_autoloaded.minZ) #should be a strictly positive integer result
		result*=2 #the least significant bit of the integer is only 1 if self_capture is true (this differentiates spots based on all the initial conditions of the calculation without cross-corruption)
		if self_capture:
			result+=1
	return result

func is_on_red_black_brown()->bool:
	if dead:
		return false
	var result: bool=false #
	var txtbk_coord: Vector2=Vector2(global_position.x, -global_position.z+13*sqrt(3)+.0001) #all positions on the right side of the board are in the 1st quadrant of
	#geometry textbook space.
	var careful_mod: int =int(txtbk_coord.y*3/sqrt(3)+.5) #the +.5 should stop the rounding error encountered when a white pawn attacks a black pawn.
	#if this doesn't work, then I will need to switch over to the 
	#update, the +.5 does work.
	
	if careful_mod%3==1:
		result=true #
	elif careful_mod%3==2:
		result=false
	else: #something went wrong, my calculation is out of whack
		print("something went wrong, pawn "+str(name)+" is at geometry textbook coordinate "+str(txtbk_coord)+" where the y*sqrt(3)/3 mod 3 equals 0, which is not supposed to be true. (it would mean the center of a triangle aligning with the bottom edge of another triangle, or with the tip)")
	return result #

func can_move_to(global_pos: Vector3, self_capture: bool=false)->bool:
	if dead:
		return false
	
	if (start_pos-global_position).length_squared()<.1 and all_hashed_positions.has(str(hash_pos(global_pos, self_capture))):
		return all_hashed_positions[hash_pos(global_pos, self_capture)]
	
	var result: bool=false
	
	var textbook_coord: Vector2=Vector2(global_pos.x-global_position.x, -(global_pos.z-global_position.z)) #this is putting the center of the current pawn at effectively (0,0) w.r.t. the places that can be moved to 
	#how a geometry textbook represents the values for the lines I drew in my notes. 
	#As long as the board triangles remain in the same size and orientation,
	#I can figure out whether a triangle is of one of two sets ({red, black, brown} or {blue, green, white}) by using a very careful mod function from
	#a geometry textbook origin that, in Godot space, would be at (0, 0, 13*sqrt(3)), but in geometry textbook space could be considered
	#as set to (0, -13*sqrt(3)) relative to the center of the board (so that the board shows up in the 1st quadrant of the XY plane on paper).
	if has_improved:
		if (global_pos-global_position).length()<=sqrt(5)*2:
			result=true
	elif not is_black_v:
		if is_on_red_black_brown():
			var places_to_go: Array[Vector2]=[Vector2(-1, sqrt(3)/3), Vector2(-1, sqrt(3)), Vector2(0, 4*sqrt(3)/3), Vector2(1, sqrt(3)), Vector2(1, sqrt(3)/3)]
			for i in places_to_go:
				if (i-textbook_coord).length()<sqrt(3)/3:
					result=true #
					break
		else :
			var places_to_go: Array[Vector2]=[Vector2(-2, 2*sqrt(3)/3), Vector2(-1, sqrt(3)), Vector2(0, 2*sqrt(3)/3), Vector2(1, sqrt(3)), Vector2(1, 2*sqrt(3)/3), Vector2(2, 2*sqrt(3)/3)]
			for i in places_to_go:
				if (i-textbook_coord).length()<sqrt(3)/3:
					result=true #
					break
			#if not result and (global_pos-global_position).length()<=4*sqrt(3)/3+sqrt(3)/6 and Vector3.FORWARD.dot(global_pos-global_position)>0: #there was an edge case of the kiddie-corner move not being recognized at one end
			#	result=true
	elif is_black_v:
		if not is_on_red_black_brown(): #everything "forward" is reversed for black, including the idea of red, black, brown pointing "forward", which they no longer do.
			var places_to_go: Array[Vector2]=[Vector2(-1, -sqrt(3)/3), Vector2(-1, -sqrt(3)), Vector2(0, -4*sqrt(3)/3), Vector2(1, -sqrt(3)), Vector2(1, -sqrt(3)/3)]
			for i in places_to_go:
				if (i-textbook_coord).length()<sqrt(3)/3:
					result=true #
					break
		else :
			var places_to_go: Array[Vector2]=[Vector2(-2, -2*sqrt(3)/3), Vector2(-1, -sqrt(3)), Vector2(0, -2*sqrt(3)/3), Vector2(1, -sqrt(3)), Vector2(1, -2*sqrt(3)/3), Vector2(2, -2*sqrt(3)/3)]
			for i in places_to_go:
				if (i-textbook_coord).length()<sqrt(3)/3:
					result=true #
					break
			#if not result and (global_pos-global_position).length()<=4*sqrt(3)/3+sqrt(3)/6 and Vector3.BACK.dot(global_pos-global_position)>0: #there was an edge case of the kiddie-corner move not being recognized at one end
			#	result=true
		
	if result and not self_capture:
		#check if the position is shared by a piece of the same color.
		if not is_black_v:
			for p in thing_autoloaded.white_player_pieces:
				if (global_pos-p.global_position).length()<sqrt(3)/5:
					result=false #
					break #the position involves self_capture.
		else: #this is the black player.
			for p in thing_autoloaded.black_player_pieces:
				if (global_pos-p.global_position).length()<sqrt(3)/5:
					result=false #
					break #the position involves self_capture.
	return result #

func full_check_of_positions():
	if len(thing_autoloaded.possible_positions)>40 and thing_autoloaded.maxZ>1: #make certain that the autoloaded script has set all the values necessary for these stable hashes of positions.
		if time_of_check<0 or (start_pos-global_position).length_squared()>.1:
			
			time_of_check=current_time
			if not is_black_v: #white player
				for pos in thing_autoloaded.possible_positions:
					var temp: bool=can_move_to(pos, true)
					var index=hash_pos(pos, true)
					all_hashed_positions[index]=temp
					if temp: #set the proper value of the position when self_capture is not allowed (false if a piece of one's own side is there)
						#previously determined that this is the white player.
						for p in thing_autoloaded.white_player_pieces:
							if (pos-p.global_position).length()<sqrt(3)/5:
								all_hashed_positions[index-1]=false #there was a piece of one's own side there.
								break #don't need to check any further.
					else:
						all_hashed_positions[index-1]=false #if you can't get there even with self-capture, then you can't get there at all
			else: #black player
				for pos in thing_autoloaded.possible_positions:
					var temp: bool=can_move_to(pos, true)
					var index=hash_pos(pos, true)
					all_hashed_positions[index]=temp
					if temp:
						#previously determined that this is the black player
						for p in thing_autoloaded.black_player_pieces:
							if (pos-p.global_position).length()<sqrt(3)/5:
								all_hashed_positions[index-1]=false #there was a piece of one's own side there.
								break #don't need to check any further.
					else:
						all_hashed_positions[index-1]=false #can't even get here when self_capture is enabled.
			start_pos=global_position #this code must appear after any call to can_move_to because can_move_to might use a comparison of start_pos to global_pos 
			#to determine whether to run the code for checking any positions (as opposed to giving back the default in the all_hashed_positions Dictionary).
			#there is thus a circular dependency here, so I have to be careful not to create a self-fulfilling prophecy.
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	current_time+=delta
	if is_black_v and global_position.z>9*sqrt(3):
		has_improved=true
	elif not is_black_v and global_position.z<-9*sqrt(3):
		has_improved=true
	if is_clicked_v:
		
		if thing_autoloaded.any_move_to_position:
			print("pawn "+str(name)+" told to move to "+str(thing_autoloaded.move_to_position)+" from "+str(global_position))
			#global_translate(thing_autoloaded.move_to_position-global_position)
			#thing_autoloaded.any_move_to_position=false
			#thing_autoloaded.any_piece_selected=false #
			#thing_autoloaded.move_to_position=Vector3()
			is_clicked_v=false #
			when_clicked_v=-10
			#thing_autoloaded.piece_selected=null #
	if global_position.y<-100:
		dead=true #
	elif global_position.y>-5 and global_position.y<5 and int(current_time+delta)>int(current_time):
		global_translate(Vector3(0, .06-global_position.y, 0))
	if global_position.y>-100 and (start_pos-global_position).length_squared()>.1:
		full_check_of_positions()

func click():
	if not is_clicked_v:
		#thing_autoloaded.piece_selected=self #
		#thing_autoloaded.any_piece_selected=true #
		is_clicked_v=thing_autoloaded.piece_clicked(self)
		if is_clicked_v:
			when_clicked_v=current_time
			print("pawn "+str(name)+" selected at "+str(global_position))
		
	
func unclick(): #where you click the same piece again in order to return to the starting options.
	
	if is_clicked_v and when_clicked_v+.1<current_time:
		when_clicked_v=-10
		is_clicked_v=false
		RenderingServer.global_shader_parameter_set("any_piece_selected", false)
		#var thing: Node=get_node("/root/piece_selected")
		thing_autoloaded.any_piece_selected=false
	elif not is_clicked_v:
		when_clicked_v=-10

func is_chosen()->bool:
	return is_clicked_v

func when_chosen()->float:
	return when_clicked_v



func is_black()->bool:
	return is_black_v
