extends Node
var piece_selected: Node3D=null
var any_piece_selected: bool=false
var move_to_position: Vector3=Vector3(0,0,0)
var when_move_to_position: float=-10
var any_move_to_position: bool=false
var white_player_pieces: Array[Node3D]=[]
var black_player_pieces: Array[Node3D]=[]
var possible_positions: Array[Vector3]=[] #the centers of each triangle, which are passed to 
	#this spot with the ready() function on triangle_bais.gd
var hashTable_pos_to_piece: Dictionary={} #translates the integer from hash_pos(global_position) to the Node3D at that position
var maxZ: float=0
var minZ: float=0
var minX: float=0
var is_black: bool=false #is the black side the "real" human player on this computer?
var time_from_selection: float=-10
var current_time: float=0
var start_pos: Vector3=Vector3(0,0,0) 
var currently_moving_piece: bool=false
const MAX_FORCE: float=100
var check_rigid: RigidBody3D=null
var moved_so_far: float=0
var prev_pos: Vector3=Vector3()
var world: World3D=null
var is_max_pos_found: bool=false #
var AI_script_node: Node=null
var first_move_happened: bool=false #if the AI is white, it must move before the player, but after that
#first move, the AI can replicate the fact that it is still moving first by moving immediately after the player plays (mathematically the same).
#since no player can capture on the first turn, we don't have much to worry about.

func set_AI(thing: Node):
	if thing.has_method("make_move"):
		AI_script_node=thing

func _ready():
	check_rigid=RigidBody3D.new()
	check_rigid.name="null"
	check_rigid.global_translate(Vector3(-10000, 0, -10000))

#hash_pos is important for replacing the need for RayCasting, because now we can use the hash_pos 
#function to reference the Vector3 position of a triangle in possible_positions (incrementing and decrementing x and z to check all 9 possible places for the center of a triangle
#then, once those triangles are found, those triangles form references to the pieces on said triangles,
#which are then checked for having global_positions within 2*sqrt(3)/3 of the line of a piece's movement (where stepping along that line of movement 
func hash_pos(global_pos: Vector3)->int:
	var result: int=0
	if global_pos.y>-500:
		if not is_max_pos_found and len(possible_positions)>40:
			for pos in possible_positions:
				if pos.z>maxZ:
					maxZ=pos.z #
					is_max_pos_found=true
				elif pos.z<minZ:
					minZ=pos.z #
				if pos.x<minX:
					minX=pos.z
					
		result=int((global_pos.x-minX)*maxZ+global_pos.z-minZ)
	return result

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
	
func reset_hashTable():
	hashTable_pos_to_piece.clear() #remove all entries and start over.
	for piece in black_player_pieces:
		var index=hash_pos(piece.global_position)
		hashTable_pos_to_piece[index]=piece
	for piece in white_player_pieces:
		var index=hash_pos(piece.global_position)
		hashTable_pos_to_piece[index]=piece
		

func piece_near(global_pos: Vector3)->Node3D:
	if len(hashTable_pos_to_piece)<2:
		return null #need to cause a null pointer exception if there was a problem.
		#for issues of not finding something, return check_rigid
	var index=hash_pos(global_pos)
	var p_list: Array[Node3D]=[]
	if hashTable_pos_to_piece.has(str(index)):
		p_list.append(hashTable_pos_to_piece[index])
	var cur: Vector3=global_pos
	cur.x=global_pos.x+1 #1
	index=hash_pos(cur)
	if hashTable_pos_to_piece.has(str(index)):
		p_list.append(hashTable_pos_to_piece[index])
	cur.x=global_pos.x
	cur.z=global_pos.z+1 #2
	
	index=hash_pos(cur)
	if hashTable_pos_to_piece.has(str(index)):
		p_list.append(hashTable_pos_to_piece[index])
	cur.x=global_pos.x-1 #3
	cur.z=global_pos.z
				
	index=hash_pos(cur)
	if hashTable_pos_to_piece.has(str(index)):
		p_list.append(hashTable_pos_to_piece[index])
	cur.x=global_pos.x
	cur.z=global_pos.z-1 #4
	
	index=hash_pos(cur)
	if hashTable_pos_to_piece.has(str(index)):
		p_list.append(hashTable_pos_to_piece[index])
	cur.x=global_pos.x+1
	cur.z=global_pos.z+1 #5
	index=hash_pos(cur)
	if hashTable_pos_to_piece.has(str(index)):
		p_list.append(hashTable_pos_to_piece[index])
	cur.x=global_pos.x-1
	cur.z=global_pos.z+1 #6
	index=hash_pos(cur)
	if hashTable_pos_to_piece.has(str(index)):
		p_list.append(hashTable_pos_to_piece[index])
	cur.x=global_pos.x+1
	cur.z=global_pos.z-1 #7
	index=hash_pos(cur)
	if hashTable_pos_to_piece.has(str(index)):
		p_list.append(hashTable_pos_to_piece[index])
	cur.x=global_pos.x-1
	cur.z=global_pos.z-1 #8
	index=hash_pos(cur)
	if hashTable_pos_to_piece.has(str(index)):
		p_list.append(hashTable_pos_to_piece[index])
	
	var result: Node3D=check_rigid
	for p in p_list:
		if (p.global_position-global_pos).length_squared()<(result.global_position-global_pos).length_squared():
			result=p #
	return result

#the ray_cast function will be used by the opponent AI script for figuring out "real" movement options.
#it won't be used in the can_move_to function because I like the fact that the player can see where pieces would be able to go if
#those pieces were actually able to move through things (as well as it allows the player to be assured through the fog that the opponent has the same pieces he or she does).
#if this returns null, then don't use the value, otherwise, if the name of the piece returned is "null", (the check_rigid), then the path is clear (or it starts and ends with two nodes: a Node3D within sqrt(3)/3 of start, a Node3D within sqrt(3)/3 of end.
#if this returns a valid Node3D piece, then that piece appears within sqrt(3)/3 of the line of the movement.
func ray_cast(start: Vector3, end: Vector3)->Node3D:
	const OFFSET_DIST: float=sqrt(3)/3
	if len(hashTable_pos_to_piece)<2:
		return null #there is a problem if the table isn't set up, this function can't be used
	var result: Node3D=check_rigid
	var steps: int=int((start-end).length()+.99)
	var df: float=1.0/steps
	var f: float=0
	var cur: Vector3=start*(1-f)+end*f #linear interpolation to the end.
	while f<1.0 and result==check_rigid:
		f+=df #has to be incremented first because it is useless to start at start, where we know that a Node3D is and we should ignore it.
		cur=start*(1-f)+end*f
		var temp: Node3D=piece_near(cur)
		if not temp==null and (temp.global_position-start).length_squared()>1/3 and (temp.global_position-end).length_squared()>1/3 and point_to_line(temp.global_position, start, end)<OFFSET_DIST:
			result=temp #this will automatically break the while loop.
		
	return result
	

func _process(delta):
	current_time+=delta
	if len(possible_positions)>40 and maxZ<1: #the triangle_basis.gd script _ready functions have happened, and this region of code has not yet happened
		for i in range(len(possible_positions)):
			if possible_positions[i].z>maxZ:
				maxZ=possible_positions[i].z #this should quickly be a value above 1.
			elif possible_positions[i].z<minZ:
				minZ=possible_positions[i].z
			if possible_positions[i].x<minX:
				minX=possible_positions[i].x
	if len(possible_positions)>40 and len(white_player_pieces)>2 and len(black_player_pieces)>2 and len(hashTable_pos_to_piece)<4:
		reset_hashTable() #make sure it is set up with all the pieces before accidents happen.
	
	if world==null and piece_selected!=null and any_piece_selected:
		world=piece_selected.get_world_3d()
	if currently_moving_piece and any_piece_selected and piece_selected!=null:
		#this means that piece_selected is a RigidBody3D and has been moving from start_pos, and has not finished moving from start_pos
		#this means that no pieces should be allowed to be clicked in the intervening time
		#if the time elapsed since the start of the move (when_move_to_position) is too long, and the piece has not moved an appropriate amount of distance,
		#then the amount of force applied (multiplied by the mass of the RigidBody3D) will be gradually ramped up to MAX_FORCE, and then the force applied 
		#will stop, and currently_moving_piece will stop, even if the piece has not moved the distance it is required to move.
		pass
		var time_diff: float=current_time-time_from_selection #how long has the movement operation taken to this point.
		moved_so_far+=(piece_selected.global_position-prev_pos).length()
		var move_diff: float=moved_so_far #how far has the piece gone? This is basically adding up the tiny discrete movements of the piece.
		var move_tot: float=(start_pos-move_to_position).length() #how far does the piece have to go overall?
		#var move_left: float=move_tot-move_diff #you will see that this is not the same as (global_position-move_to_position).length()
			#when the piece gets deflected in its movement by an intervening piece, it will try to move in the general direction
			#it was moving, but no longer to the chosen target position, and it will not try moving any farther than
			#the total distance it was supposed to move in the first place (or, at least, the force won't continue farther than that).
		var rigid: RigidBody3D=piece_selected
		var rel_move: Vector3=(move_to_position-piece_selected.global_position).normalized() #the normalized vector of where to move to.
		
		if time_diff>1 and move_diff/move_tot<.5:
			rigid.apply_force(rel_move*rigid.mass*min(MAX_FORCE, 1+time_diff*time_diff))
		if time_diff<=1 and move_diff/move_tot<.1:
			rigid.apply_force(rel_move*rigid.mass*min(MAX_FORCE, 1+time_diff))
		if move_diff/move_tot<.7:
			rigid.apply_force(rel_move*rigid.mass*min(MAX_FORCE, time_diff + time_diff*time_diff*time_diff/1000))
		if move_diff/move_tot<.8:
			rigid.apply_force(rel_move*rigid.mass*min(MAX_FORCE, time_diff + time_diff*time_diff*time_diff/10000)*delta)
		if move_diff/move_tot<.9:
			rigid.apply_force(rel_move*rigid.mass*min(MAX_FORCE, time_diff + time_diff*time_diff*time_diff/100000)*delta)
		elif move_diff/move_tot<.95 and time_diff<10:
			rigid.apply_force(rel_move*rigid.mass*max(0, min(MAX_FORCE-rigid.linear_velocity.length(), time_diff ))*delta)
		elif move_diff/move_tot<.99 and time_diff<10:
			rigid.apply_force(rel_move*rigid.mass*min(MAX_FORCE-rigid.linear_velocity.length(), time_diff)*delta)
		else:
			currently_moving_piece=false #
			any_move_to_position=false #
			any_piece_selected=false
			RenderingServer.global_shader_parameter_set("any_piece_selected", false)
		prev_pos=piece_selected.global_position
	
func piece_clicked(piece: Node3D)->bool:
	if currently_moving_piece:
		return false #can't click a new piece while a previous piece is moving.
	#this both checks if enough time has passed to make a new selection (if not enough time has passed, then returns false and doesn't change the values).
	#it also, if it returns true, then, it chooses the piece selected thus.
	if piece==piece_selected:
		return true
	else:
		if time_from_selection+1<current_time or not any_piece_selected:
			piece_selected=piece
			time_from_selection=current_time
			any_piece_selected=true
			any_move_to_position=false #
			when_move_to_position=-10 #this number needs to be larger than "time_from_selection" in order to move the piece there.
			RenderingServer.global_shader_parameter_set("any_piece_selected", true)
			RenderingServer.global_shader_parameter_set("selected_piece_position", piece_selected.global_position)
			return true #
		else:
			return false

func translate_to_geometry_txtbk(global_pos: Vector3)->Vector2:
	return Vector2(global_pos.x, -global_pos.z)
func translate_from_geometry_txtbk(effective_pos: Vector2)->Vector3:
	return Vector3(effective_pos.x, .1, -effective_pos.y)

func move_piece_to(global_pos: Vector3)->bool: 
	global_pos.y=.1 #make sure that we aren't sending out pieces below the grid.
	if currently_moving_piece or piece_selected==null or (not any_piece_selected):
		print("line 91")
		return false #can't choose a new spot to move to while moving a piece.
	var result=false #
	#this function will check if the piece to move is a RigidBody3D, in which case currently_moving_piece 
	#gets set to true, and force applied will gradually ramp up to MAX_FORCE, then stop, and reopen choosing a new piece.
	print("line 96") #is printed
	start_pos=piece_selected.global_position #it's already established above that piece_selected is not null, which means that it MUST be of Node3D type.
	move_to_position=start_pos
	var piece_removed: Node3D=null
	if piece_selected.has_method("can_move_to"):
		print("line 98") #is printed
		if piece_selected.can_move_to(global_pos) and current_time>time_from_selection:
			print("line 100") #is printed
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
				
				if piece_selected!=null and not str(piece_selected.name).begins_with("k") and (piece_selected.global_position-start_pos).length()<sqrt(3)/3: #the knight and spiral rook operate differently
					#The spiral rook falls back on straight line movement when it can't move in a spiral.
					print("line 116") #is printed (correct operation since I was not yet using knights nor spiral rooks.
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
								move_to_position=collision.collider.global_position
								piece_removed=collision.collider
								#piece_selected.global_translate(collision.collider.global_position-start_pos)
								#collision.collider.global_translate(Vector3(0, -10000, 0)) #killing off this piece. (Allows an easier time resetting the game to the pieces in their start locations. (easier relative to using queue_free))
								if str(collision.collider.name).begins_with("king"): 
									print("White wins! Black loses.")
								
								any_move_to_position=false
								
							elif not collision.collider.is_black() and piece_selected.is_black():
								print("line 149")
								move_to_position=collision.collider.global_position
								piece_removed=collision.collider
								#piece_selected.global_translate(collision.collider.global_position-start_pos)
								#collision.collider.global_translate(Vector3(0, -10000, 0)) #killing off this piece. (Allows an easier time resetting the game to the pieces in their start locations. (easier relative to using queue_free))
								if str(collision.collider.name).begins_with("king"): 
									print("Black wins! White loses.")
								
								any_move_to_position=false
								
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
								move_to_position.y=piece_selected.global_position.y
								#piece_selected.global_translate(move_to_position-piece_selected.global_position)
								
								#any_move_to_position=false
								
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
								#print("collider's parent: ", str(collision.collider.get_parent()))
								#print("collider's parent's name: ", str(collision.collider.get_parent().name))
								#print("collider's parent's children: ", str(collision.collider.get_parent().get_children()))
								var triangle: Node3D=collision.collider.get_parent()
								var center_triangle: Node3D=triangle.find_child("center_triangle")
								#print("collider's triangle's center: ", str(center_triangle), " at ", str(center_triangle.global_position))
								if str(collision.collider.get_parent().name).begins_with("triangl"):
									#print("moving piece "+str(piece_selected.name)+" to triangle "+str(triangle)+" child of "+str(triangle.get_parent_node_3d())) #NOT printed (incorrect operation, means that a ray going straight down doesn't detect a triangle).
									move_to_position=center_triangle.global_position
									move_to_position.y=piece_selected.global_position.y
									#var trans_diff: Vector3=move_to_position-piece_selected.global_position
									#trans_diff.y=0
									#piece_selected.global_translate(trans_diff)
									
									any_move_to_position=false
									
							else: #this is where a goto would be handy
								if collision.collider.is_black() and not piece_selected.is_black():
									move_to_position=collision.collider.global_position
									piece_removed=collision.collider
									#piece_selected.global_translate(collision.collider.global_position-start_pos)
									#collision.collider.global_translate(Vector3(0, -10000, 0)) #killing off this piece. (Allows an easier time resetting the game to the pieces in their start locations. (easier relative to using queue_free))
									if str(collision.collider.name).begins_with("king"): 
										print("White wins! Black loses.")
									
									any_move_to_position=false
									
								elif not collision.collider.is_black() and piece_selected.is_black():
									print("line 149")
									move_to_position=collision.collider.global_position
									#piece_selected.global_translate(collision.collider.global_position-start_pos)
									piece_removed=collision.collider
									#collision.collider.global_translate(Vector3(0, -10000, 0)) #killing off this piece. (Allows an easier time resetting the game to the pieces in their start locations. (easier relative to using queue_free))
									if str(collision.collider.name).begins_with("king"): 
										print("Black wins! White loses.")
									
									any_move_to_position=false
									
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
								move_to_position=oppo.global_position
								#piece_selected.global_translate(oppo.global_position-piece_selected.global_position)
								piece_removed=oppo
								#oppo.global_translate(Vector3(0, -10000, 0)) #kill the opponent piece.
								if str(oppo.name).begins_with("king"):
									print("White wins! Black loses.")
								
								any_move_to_position=false
								
							elif not oppo.is_black() and piece_selected.is_black():
								piece_removed=oppo
								move_to_position=oppo.global_position
								#piece_selected.global_translate(oppo.global_position-piece_selected.global_position)
								#oppo.global_translate(Vector3(0, -10000, 0)) #kill the opponent piece.
								if str(oppo.name).begins_with("king"):
									print("Black wins! White loses.")
								
								any_move_to_position=false
								
						elif str(collision.collider.get_parent().name).begins_with("triang"):
							var place: Node3D=collision.collider.get_parent() #
							move_to_position=place.find_child("center_triangle").global_position
							#piece_selected.global_translate(place.find_child("center_triangle").global_position-piece_selected.global_position)
							
							any_move_to_position=false
							
				#the spiral rook falls back on using spiral movement when it can't make a straight line move
				
			result=true
	if piece_selected!=null and (start_pos-move_to_position).length_squared()>1/3:
		if is_black and AI_script_node!=null and not first_move_happened:
			AI_script_node.make_move()
			first_move_happened=true
		piece_selected.global_translate(move_to_position-piece_selected.global_position)
		if piece_removed!=null:
			piece_removed.global_translate(Vector3(0, -10000, 0))
		reset_hashTable() #need to figure out where all the pieces are again after the player moved things.
		if AI_script_node!=null:
			AI_script_node.make_move()
		piece_selected=null # waiting until after the AI makes a move allows it to be more efficient in figuring out which human piece moved.
		any_piece_selected=false
		
	elif piece_selected!=null:
		any_piece_selected=true
	else:
		piece_selected=null
		any_move_to_position=false #
		any_piece_selected=false
	return result #
