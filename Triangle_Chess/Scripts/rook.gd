extends StaticBody3D
#Note: this script was copied from bishop.gd, so needed to use the pawn.gd method of finding whether the current triangle it is on is pointing up or down.

const degree_variance: float=1
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
var on_red_black_brown: bool=false

var thing_autoloaded: Node=null

# Called when the node enters the scene tree for the first time.
func _ready():
	material=$MeshInstance3D
	if global_position.z<0:
		is_black_v=true
		material.set_instance_shader_parameter("black", true)
		$rook_defender/MeshInstance3D.set_instance_shader_parameter("black", true)
	else:
		is_black_v=false
		material.set_instance_shader_parameter("black", false)
		$rook_defender/MeshInstance3D.set_instance_shader_parameter("black", false)
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
		rotation_degrees.y=90
	elif careful_mod%3==2:
		result=false
		rotation_degrees.y=-90
	else: #something went wrong, my calculation is out of whack
		print("something went wrong, rook "+str(name)+" is at geometry textbook coordinate "+str(txtbk_coord)+" where the y*sqrt(3)/3 mod 3 equals 0, which is not supposed to be true. (it would mean the center of a triangle aligning with the bottom edge of another triangle, or with the tip)")
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

func point_to_line(global_pos: Vector3, start_pos: Vector3, end_pos: Vector3)->float:
	var result: float=0
	if global_pos.y<-500: #we don't waste time on dead pieces.
		result=1000000
	else:
		var a: float=(start_pos-end_pos).length()
		var b: float=(end_pos-global_pos).length()
		var c: float=(global_pos-start_pos).length()
		#use Heron's formula to find the area of the triangle whose vertices are at the three initial vector points.
		var area: float=0.25*sqrt((a+b+c)*(-a+b+c)*(a-b+c)*(a+b-c))
		#then I can use the reverse of area=1/2*base*height to find the height (where base is the length "a" from start to end, therefore height would be from global_pos to the generalized line from start to end)
		result=2*area/a 
		
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
	
	global_pos.x=absf(global_pos.x)
	global_pos.y=0
	global_pos.z=absf(-global_pos.z) #due to the fact that I want to use the sensible +60 degree rotation of the Vector3.RIGHT line with respect to Vector3.UP to 
	#find the other vector.
	#check that the direction of the vector makes sense:
	var exists_a_dir: bool=(equation_pos.length()>sqrt(3)/3)
	
	#because I have now made global_pos be in quadrant 1, I can just compare it against 2 lines:
	#a line from Vector3(0, 0, 0) to Vector3(1, 0, 0)
	#a line from Vector3(0, 0, 0) to Vector3(1, 0, sqrt(3))
	#then I check that global_pos is within sqrt(3)/2 of that line.
	if exists_a_dir:
		var d1: float=point_to_line(global_pos, Vector3.ZERO, Vector3.RIGHT)
		var line_2: Vector3=global_pos.rotated(Vector3.UP, deg_to_rad(60))
		var d2: float=min(d1, point_to_line(line_2, Vector3.ZERO, Vector3.RIGHT))
		if d2<sqrt(3)/2:
			result=true
	
	
	if exists_a_dir and false:
		#the spot is farther from this spot than the radius of one circle inside a triangle.
		var angle=Vector3.RIGHT.angle_to(global_pos)
		var deg_angle=rad_to_deg(angle) #this should be a positive value whose max is 180
		if deg_angle>-degree_variance and deg_angle<degree_variance:
			result=true #
		elif deg_angle>60-degree_variance and deg_angle<60+degree_variance:
			result=true #
		elif deg_angle>120-degree_variance and deg_angle<120+degree_variance:
			result=true #
		elif deg_angle>179-degree_variance and deg_angle<181+degree_variance:
			result=true #
		else:
			global_pos.z+=sqrt(3)/3
			angle=Vector3.RIGHT.angle_to(global_pos)
			deg_angle=rad_to_deg(angle) #this should be a positive value whose max is 180
			if deg_angle>-degree_variance and deg_angle<degree_variance:
				result=true #
			elif deg_angle>60-degree_variance and deg_angle<60+degree_variance:
				result=true #
			elif deg_angle>120-degree_variance and deg_angle<120+degree_variance:
				result=true #
			elif deg_angle>179-degree_variance and deg_angle<181+degree_variance:
				result=true #
			else:
				global_pos.x+=.1
				angle=Vector3.RIGHT.angle_to(global_pos)
				deg_angle=rad_to_deg(angle) #this should be a positive value whose max is 180
				if deg_angle>-degree_variance and deg_angle<degree_variance:
					result=true #
				elif deg_angle>60-degree_variance and deg_angle<60+degree_variance:
					result=true #
				elif deg_angle>120-degree_variance and deg_angle<120+degree_variance:
					result=true #
				elif deg_angle>179-degree_variance and deg_angle<181+degree_variance:
					result=true #
				else:
					global_pos.x-=.2
					angle=Vector3.RIGHT.angle_to(global_pos)
					deg_angle=rad_to_deg(angle) #this should be a positive value whose max is 180
					if deg_angle>-degree_variance and deg_angle<degree_variance:
						result=true #
					elif deg_angle>60-degree_variance and deg_angle<60+degree_variance:
						result=true #
					elif deg_angle>120-degree_variance and deg_angle<120+degree_variance:
						result=true #
					elif deg_angle>179-degree_variance and deg_angle<181+degree_variance:
						result=true #
					else:
						result=false
				#global_pos.z-=2*sqrt(3)/3
				#angle=Vector3.RIGHT.angle_to(global_pos)
				#deg_angle=rad_to_deg(angle) #this should be a positive value whose max is 180
				#if deg_angle>-degree_variance and deg_angle<degree_variance:
				#	result=true #
				#elif (deg_angle>49.107-degree_variance and deg_angle<49.107+degree_variance) or (deg_angle>55.285-degree_variance and deg_angle<55.285+degree_variance):
				#	result=true #
				#elif (deg_angle>49.107+60-degree_variance and deg_angle<49.107+60+degree_variance) or (deg_angle>55.285+60-degree_variance and deg_angle<55.285+60+degree_variance):
				#	result=true #
				#elif (deg_angle>49.107+120-degree_variance and deg_angle<49.107+120+degree_variance) or (deg_angle>55.285+120-degree_variance and deg_angle<55.285+120+degree_variance):
				#	result=true #
				#else:
				#	result=false
		#check with global_pos up and down by sqrt(3)/3 to make sure both possible centers are considered
			
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	current_time+=delta
	if global_position.y<-100:
		dead=true #
	elif global_position.y>-5 and global_position.y<5 and int(current_time+delta)>int(current_time):
		global_translate(Vector3(0, .06-global_position.y, 0))
		on_red_black_brown=is_on_red_black_brown()
	if global_position.y>-100 and (start_pos-global_position).length_squared()>.1:
		full_check_of_positions()
	pass





	
