extends StaticBody3D
#Note: this script was copied from bishop.gd, so needed to use the pawn.gd method of finding whether the current triangle it is on is pointing up or down.

var current_time: float=0
var is_chosen_v: bool=false 
var when_chosen_v: float=-10
var is_black_v: bool=false
var material: GeometryInstance3D=null
var start_pos: Vector3=Vector3()
var was_moving: bool=false
var has_moved: bool=false



var all_hashed_positions: Dictionary={}
var time_of_check: float=-1
var thing_autoloaded: Node=null

# Called when the node enters the scene tree for the first time.
func _ready():
	material=$MeshInstance3D
	if global_position.z<0:
		is_black_v=true
		material.set_instance_shader_parameter("black", true)
	else:
		is_black_v=false
		material.set_instance_shader_parameter("black", false)
	current_time=0
	is_chosen_v=false 
	thing_autoloaded=get_node("/root/piece_selected")
	pass # Replace with function body.

func is_chosen()->bool:
	return is_chosen_v

func is_black()->bool:
	return is_black_v

func unclick(): #where you click the same piece again in order to return to the starting options.
	if is_chosen_v and when_chosen_v+.1<current_time:
		when_chosen_v=-10
		is_chosen_v=false
		RenderingServer.global_shader_parameter_set("any_piece_selected", false)
		#var thing_autoloaded: Node=get_node("/root/piece_selected")
		thing_autoloaded.any_piece_selected=false
	elif not is_chosen_v:
		when_chosen_v=-10

func click():
	when_chosen_v=current_time
	if is_chosen_v==false:
		
		#var thing_autoloaded: Node=get_node("/root/piece_selected")
		is_chosen_v=thing_autoloaded.piece_clicked(self)
		#thing_autoloaded.piece_selected=self
		#thing_autoloaded.any_piece_selected=true
		thing_autoloaded.any_move_to_position=false #need to make sure that it doesn't start moving before the user chooses where to put it.
		#var really_is: bool=get_node("/root/any_piece_selected")
	#is_chosen_v=true #

func when_chosen()->float:
	return when_chosen_v
	
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


func can_move_to(global_pos1: Vector3, self_capture: bool=false)->bool:
	if dead:
		return false
	
	if (start_pos-global_position).length_squared()<.1 and all_hashed_positions.has(str(hash_pos(global_pos1, self_capture))):
		return all_hashed_positions[hash_pos(global_pos1, self_capture)]
	
	var result: bool=false
	var global_pos: Vector3=global_pos1- global_position #the relative vector from this triangle to that spot.
	#note: I need to check that this direction makes sense in light of the points of the triangle (that the line is not bi-directional).
	var equation_pos: Vector2=Vector2(global_pos.x, -global_pos.z) #this is the appearance of the x-y plane in 2D in a geometry textbook.
	
	#check that the direction of the vector makes sense:
	var exists_a_dir: bool=(equation_pos.length()>sqrt(3)/3)
	if exists_a_dir:
		#the spot is farther from this spot than the radius of one circle inside a triangle.
		if global_pos.length()>=sqrt(15)-sqrt(3)/6 and global_pos.length()<=2*sqrt(5)+sqrt(3)/6: 
			#a knight in chess moves two spaces in one direction, then 1 space at a 90 degree angle to where it was starting to move.
			#this forms a right triangle with one side length of 2, and one side length of 1. the hypotenuse is then length =sqrt(2*2+1*1)=sqrt(5)
			#the "distance" metric in this game is based on the size of the triangle, but there are two ways of saying the "size" of an equilateral triangle
			#one way is to say "the height of the triangle" (this is from the tip of the triangle to the opposite side), 
			#the other way is to say "the base of the triangle" (every side length is the same, 2 meters)
			#thus, if a spot is between sqrt(5)*height and sqrt(5)*base from where the knight is currently, then that ought to be a valid spot.
			#the sqrt(3)/6 is half of the radius of a circle inscribed in one triangle, and provides a margin of error 
			#which allows the knight 3 more spaces to move, and makes the move options look more like a proper circle.
			#it does make the knight marginally faster in the straight line move that neither a bishop nor rook can make, which is proper 
			#(given how vastly more powerful this game has made rooks and bishops)
			result=true 
	if result and not self_capture:
		#check if the position is shared by a piece of the same color.
		if not is_black_v:
			for p in thing_autoloaded.white_player_pieces:
				if (global_pos1-p.global_position).length()<sqrt(3)/5:
					result=false #
					break #the position involves self_capture.
		else: #this is the black player.
			for p in thing_autoloaded.black_player_pieces:
				if (global_pos1-p.global_position).length()<sqrt(3)/5:
					result=false #
					break #the position involves self_capture.
	return result

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
	if global_position.y<-100:
		dead=true #
	elif global_position.y>-5 and global_position.y<5 and int(current_time+delta)>int(current_time):
		global_translate(Vector3(0, .06-global_position.y, 0))
	if global_position.y>-100 and (start_pos-global_position).length_squared()>.1:
		full_check_of_positions()
	pass




	
