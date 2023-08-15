extends OmniLight3D

var current_time: float=0
var my_prev_change_time: float=0
var human_change_time: float=3 #when human_change_time>my_prev_change_time and everything is already set up and human_change_time<current_time, then play my move.
var thing_autoloaded: Node=null #
var possible_positions: Array[Vector3]=[] #will take the values of all $center_triangle.global_position after 1 second of gameplay has elapsed
	#(to give time for all the other _ready() functions to execute)
var my_pieces: Array[Node3D]=[]
var human_pieces: Array[Node3D]=[]
var human_piece_positions: Array[Vector3]=[] #these vectors are ordered using the same ordering as human_pieces 
	#which is usable since pieces that are killed are never deleted, just moved thousands of meters below the xz plane.

var is_max_pos_found: bool=false #allows me to find the maximum possible z position exactly once (that number is important for stability in the hashing algorithm)
var max_z_pos: float=0
var min_z_pos: float=0 #I know it is going to be less than this
var min_x_pos: float=0

#hash_pos is important for replacing the need for RayCasting, because now we can use the hash_pos 
#function to reference the Vector3 position of a triangle in possible_positions (incrementing and decrementing x and z to check all 9 possible places for the center of a triangle
#then, once those triangles are found, those triangles form references to the pieces on said triangles,
#which are then checked for having global_positions within 2*sqrt(3)/3 of the line of a piece's movement (where stepping along that line of movement 
func hash_pos(global_pos: Vector3)->int:
	var result: int=0
	if global_pos.y>-500:
		if not is_max_pos_found and len(possible_positions)>40:
			for pos in possible_positions:
				if pos.z>max_z_pos:
					max_z_pos=pos.z #
					is_max_pos_found=true
				elif pos.z<min_z_pos:
					min_z_pos=pos.z #
				if pos.x<min_x_pos:
					min_x_pos=pos.z
					
		result=int((global_pos.x-min_x_pos)*max_z_pos+global_pos.z-min_z_pos)
	return result

# Called when the node enters the scene tree for the first time.
func _ready():
	thing_autoloaded=get_node("/root/piece_selected")
	thing_autoloaded.set_AI(self)
	pass # Replace with function body.

#this function is what is called by the thing_autoloaded (which_selected.gd) script, it is called every time a player actually moves a piece.
func make_move(): #this function uses the thing_autoloaded.ray_cast(start: Vector3, end: Vector3) function
	#to figure out if a piece is in the way of another piece when creating the hashTable of where pieces can go.
	#that function (thing_autoloaded.ray_cast(start: Vector3, end: Vector3))
	#is not what is used to actually move pieces finally, because that would be cheating (defeating the point of the rook_defender staticbodies)
	
	#there is a priority list for making attacks:
	#1: attack and kill the opponent king if it is available.
	#2: stop my own king from being killed in the next turn.
	#3: move my piece so that it is on a triangle not under my opponent's attack, but where it is attacking my opponent's king.
	#4: move my piece so that it is both (a) protected by another of my own pieces, and (b) the opponent piece attacking it is of equal or greater value
	# using the value chart: (100) king, (9) spiral_rook, (7) rook, (3) bishop, (2) knight, (1) pawn
	pass

#The following function was not managable, I need a better system for finding distance from a point global_pos to the line from start_pos to end_pos
#func point_to_line(point: Vector2, line: Vector3)->float: #line is Vector3(a,b,c) where ax+by+c=0 is the equation of the line
#	var num: float=line.x*point.x+line.y*(point.y)+line.z 
#	#need to translate the point's position from Godot editor (-z axis is forward horizontal) to 2D geometry math textbook (+y axis is forward horizontal)
#	num=abs(num)
#	var denom=line.x*line.x+line.y*line.y
#	denom=sqrt(denom)
#	return num/denom

func point_to_line(global_pos: Vector3, start_pos: Vector3, end_pos: Vector3)->float:
	var result: float=0
	if global_pos.y<-500: #we don't waste time on dead pieces.
		result=1000000
	else:
		var a: float=(start_pos-end_pos).length()
		var b: float=(end_pos-global_pos).length()
		var c: float=(global_pos-start_pos).length()
		#use Heron's formula to find the are of the triangle whose vertices are at the three initial vector points.
		var area: float=0.25*sqrt((a+b+c)*(-a+b+c)*(a-b+c)*(a+b-c))
		#then I can use the reverse of area=1/2*base*height to find the height (where base is the length "a" from start to end, therefore height would be from global_pos to the generalized line from start to end)
		result=2*area/a 
		
	return result
	
#the following function replaces the need to check for RayCasts, at least when it comes to making the initial decision 
#(the actual movement of the piece must follow the same function design that the player pieces move along)
func raycast(start_pos: Vector3, end_pos: Vector3)->Vector3:
	#the result is where the function stops (which must also be the center_triangle of a triangle) due to something being in my way.
	var result: Vector3=start_pos
	var f: float=0 #gets incremented by df, which is the inverse of the number of steps to get to end_pos.
	var steps: int=int(2*(start_pos-end_pos).length())
	var df: float=1.0/steps
	
	return result

#I am going to create a list of the variables used in move_piece_to, 
#and then go next to each variable list a reason for why this variable is not going to be included.
#global_pos: Vector3
#currently_moving_piece: bool
#piece_selected: Node3D
#any_piece_selected: bool
#result: bool (local to the function)
#start_pos: Vector3 (local to the function)
#time_from_selection: float (irrelevant since this assumes a human playing)
#currently_moving_piece: bool (irrelevent since it assumes a RigidBody)
#moved_so_far: float (irrelevent since it assumes a RigidBody)
#prev_pos: Vector3



"""
func move_piece_to(global_pos: Vector3)->bool: 
	global_pos.y=.1 #make sure that we aren't sending out pieces below the grid.
	if currently_moving_piece or piece_selected==null or (not any_piece_selected):
		print("line 91")
		return false #can't choose a new spot to move to while moving a piece.
	var result=false #
	#this function will check if the piece to move is a RigidBody3D, in which case currently_moving_piece 
	#gets set to true, and force applied will gradually ramp up to MAX_FORCE, then stop, and reopen choosing a new piece.
	print("line 96") #is printed
	if piece_selected.has_method("can_move_to"):
		print("line 98") #is printed
		if piece_selected.can_move_to(global_pos) and current_time>time_from_selection:
			print("line 100") #is printed
			start_pos=piece_selected.global_position 
			start_pos.y=.1
			time_from_selection=current_time 
			if piece_selected.get_class()==check_rigid.get_class():
				print("line 105") #NOT printed (which is correct operation since I wasn't using RigidBody3D
				currently_moving_piece=true
				moved_so_far=0
				prev_pos=start_pos
			else:
				print("line 110") #is printed
				currently_moving_piece=false
				RenderingServer.global_shader_parameter_set("any_piece_selected", false)
				
				if piece_selected!=null and not str(piece_selected.name).begins_with("k") and (piece_selected.global_position-start_pos).length()<sqrt(3)/3: #the knights operate differently
					#The spiral rook falls back on straight line movement
					var steps: int=int((global_pos-start_pos).length()/(2*sqrt(3)/3)+.5)
					var cur_pos: Vector3=start_pos
					var step_f: float=1/float(steps)
					var step_delta: float=step_f
					var next_pos: Vector3=(global_pos*step_f+start_pos*(1-step_f))
					cur_pos.y=.1
					next_pos.y=.1
					var ignore: Array[RID]=[piece_selected.get_rid()]
					for ch in piece_selected.get_children():
						if ch.has_method("get_rid"):
							var ch_rid: RID=ch.get_rid()
							ignore.append(ch_rid)
					var query: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(cur_pos, next_pos, 4294967295, ignore)
					var collision: Dictionary=world.direct_space_state.intersect_ray(query)
					print("initial ", collision)																		#avoids hitting one's own rook_defender
					var col_v: Vector3= (piece_selected.global_position)
					if collision.has("collider"):
						col_v=collision.collider.global_position-col_v
					var hit_self: Vector2=Vector2(col_v.x, col_v.z)
					while step_f<1 and (collision==null or collision.is_empty() or not collision.has("collider") or hit_self.length()<sqrt(3)/12):
						step_f+=step_delta
						cur_pos=next_pos
						next_pos=(global_pos*min(1, step_f)+start_pos*max(0, (1-step_f)))
						cur_pos.y=.1
						next_pos.y=.1
						query.set_from(cur_pos) #=PhysicsRayQueryParameters3D.create(cur_pos, next_pos, 4294967295, [piece_selected.get_rid()])
						query.set_to(next_pos)
						collision=world.direct_space_state.intersect_ray(query)
						print("while ", collision)
						col_v= (piece_selected.global_position)
						if collision.has("collider"):
							col_v=collision.collider.global_position-col_v
						hit_self=Vector2(col_v.x, col_v.z)
					#now check if the collision is the opposite color as this piece, in which case it will take it's spot. Otherwise, this piece will move to the spot immediately prior 
					#(use a ray cast downward to see the triangle, then move to the center of the triangle, up sufficiently).
					print("line 137") #is printed
					if collision!=null and collision.has("collider"):
						if collision.collider.has_method("is_black"):
							print("line 139") #NOT printed (correct operation since I was moving a pawn to an empty space)
							if collision.collider.is_black() and not piece_selected.is_black():
								piece_selected.global_translate(collision.collider.global_position-start_pos)
								collision.collider.global_translate(Vector3(0, -10000, 0)) #killing off this piece. (Allows an easier time resetting the game to the pieces in their start locations. (easier relative to using queue_free))
								if str(collision.collider.name).begins_with("king"): 
									print("White wins! Black loses.")
								piece_selected=null #
								any_move_to_position=false
								any_piece_selected=false
							elif not collision.collider.is_black() and piece_selected.is_black():
								print("line 149")
								piece_selected.global_translate(collision.collider.global_position-start_pos)
								collision.collider.global_translate(Vector3(0, -10000, 0)) #killing off this piece. (Allows an easier time resetting the game to the pieces in their start locations. (easier relative to using queue_free))
								if str(collision.collider.name).begins_with("king"): 
									print("Black wins! White loses.")
								piece_selected=null #
								any_move_to_position=false
								any_piece_selected=false
						else:
							print("line 158")
							next_pos=cur_pos
							cur_pos.y=10
							next_pos.y=-10 #the triangle should definitely be hit by the ray.
							query.set_from(cur_pos)
							query.set_to(next_pos)
							collision=world.direct_space_state.intersect_ray(query)
							#apparently, the below code wasn't reached on July 28th at 2:11 pm, the triangle wasn't detected.
							if collision!=null and collision.has("collider") and str(collision.collider.get_parent().name).begins_with("triangl"):
								var triangle: Node3D=collision.collider.get_parent()
								print("moving piece "+str(piece_selected.name)+" to triangle "+str(triangle)+" child of "+str(triangle.get_parent_node_3d()))
								move_to_position=triangle.find_child("center_triangle").global_position
								move_to_position.y=.1
								piece_selected.global_translate(move_to_position-piece_selected.global_position)
								piece_selected=null #
								any_move_to_position=false
								any_piece_selected=false
					else:
						print("line 176") #is printed (correct operation since the corresponding if was false)
						cur_pos=global_pos
						next_pos=cur_pos
						cur_pos.y=10
						next_pos.y=-10 #the triangle should definitely be hit by the ray.
						query.set_from(cur_pos)
						query.set_to(next_pos)
						collision=world.direct_space_state.intersect_ray(query)
						print(str(collision))
						
						if collision!=null and collision.has("collider"):
							if not collision.collider.has_method("is_black"): #should be a non-chesspiece object.
								print("collider's parent: ", str(collision.collider.get_parent()))
								print("collider's parent's name: ", str(collision.collider.get_parent().name))
								print("collider's parent's children: ", str(collision.collider.get_parent().get_children()))
								var triangle: Node3D=collision.collider.get_parent()
								var center_triangle: Node3D=triangle.find_child("center_triangle")
								print("collider's triangle's center: ", str(center_triangle), " at ", str(center_triangle.global_position))
								if str(collision.collider.get_parent().name).begins_with("triangl"):
									print("moving piece "+str(piece_selected.name)+" to triangle "+str(triangle)+" child of "+str(triangle.get_parent_node_3d())) #NOT printed (incorrect operation, means that a ray going straight down doesn't detect a triangle).
									move_to_position=center_triangle.global_position
									move_to_position.y=.1
									var trans_diff: Vector3=move_to_position-piece_selected.global_position
									trans_diff.y=0
									piece_selected.global_translate(trans_diff)
									piece_selected=null #
									any_move_to_position=false
									any_piece_selected=false #
							else: #this is where a goto would be handy
								if collision.collider.is_black() and not piece_selected.is_black():
									piece_selected.global_translate(collision.collider.global_position-start_pos)
									collision.collider.global_translate(Vector3(0, -10000, 0)) #killing off this piece. (Allows an easier time resetting the game to the pieces in their start locations. (easier relative to using queue_free))
									if str(collision.collider.name).begins_with("king"): 
										print("White wins! Black loses.")
									piece_selected=null #
									any_move_to_position=false
									any_piece_selected=false
								elif not collision.collider.is_black() and piece_selected.is_black():
									print("line 149")
									piece_selected.global_translate(collision.collider.global_position-start_pos)
									collision.collider.global_translate(Vector3(0, -10000, 0)) #killing off this piece. (Allows an easier time resetting the game to the pieces in their start locations. (easier relative to using queue_free))
									if str(collision.collider.name).begins_with("king"): 
										print("Black wins! White loses.")
									piece_selected=null #
									any_move_to_position=false
									any_piece_selected=false
				elif piece_selected!=null and str(piece_selected.name).begins_with("k"): #both king and knight should use this code in order that kings don't get stopped by 
					#a kiddie-corner pawn.
					print("line 193")
					var cur_pos: Vector3=global_pos
					cur_pos.y=10
					#var step_f: float=1/float(steps)
					#var step_delta: float=step_f
					var next_pos: Vector3=(global_pos)
					next_pos.y=-10
					var query: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(cur_pos, next_pos, 4294967295, [piece_selected.get_rid()])
					var collision=world.direct_space_state.intersect_ray(query)
					if collision!=null and collision.has("collider"):
						print("line 203")
						#either a triangle (open spot) or a piece (check to see if opposite color, otherwise do nothing).
						if collision.collider.has_method("is_black"):
							var oppo: Node3D=collision.collider
							if oppo.is_black() and not piece_selected.is_black():
								piece_selected.global_translate(oppo.global_position-piece_selected.global_position)
								oppo.global_translate(Vector3(0, -10000, 0)) #kill the opponent piece.
								if str(oppo.name).begins_with("king"):
									print("White wins! Black loses.")
								piece_selected=null #
								any_move_to_position=false
								any_piece_selected=false
							elif not oppo.is_black() and piece_selected.is_black():
								piece_selected.global_translate(oppo.global_position-piece_selected.global_position)
								oppo.global_translate(Vector3(0, -10000, 0)) #kill the opponent piece.
								if str(oppo.name).begins_with("king"):
									print("Black wins! White loses.")
								piece_selected=null #
								any_move_to_position=false
								any_piece_selected=false
						elif str(collision.collider.get_parent().name).begins_with("triang"):
							var place: Node3D=collision.collider.get_parent() #
							piece_selected.global_translate(place.find_child("center_triangle").global_position-piece_selected.global_position)
							piece_selected=null #
							any_move_to_position=false
							any_piece_selected=false #
				#the spiral rook falls back on using spiral movement when it can't make a straight line move
				
			result=true
	return result #
"""
