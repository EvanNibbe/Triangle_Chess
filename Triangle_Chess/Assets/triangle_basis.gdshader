shader_type spatial;
instance uniform bool selectable;
instance uniform bool is_selected;
instance uniform bool piece_selectable;
//uniform bool piece_selected; //redundant
instance uniform bool exists_a_piece_to_move_here;
instance uniform vec3 center_position; //the center of this triangle.  in global coordinates.
global uniform bool any_piece_selected;
global uniform vec3 selected_piece_position; //this, combined with center_position (with default of false if any_piece_selected is false)
	//, allows us to find whether piece_selected would be true here.

render_mode alpha_to_coverage, blend_mix;

void vertex() {
	COLOR=vec4(0.0);
	if (any_piece_selected && length(center_position-selected_piece_position)<sqrt(3.0)/3.0) { //sqrt(3)/3 is 1/2 of the shortest distance there can exist from the center of one triangle to the next.
		COLOR=vec4(0.0, 0.0, 1.0, 1.0);
	} else if (any_piece_selected && is_selected) { //this is not the piece that is selected, this is the spot that piece moves to.
		COLOR=vec4(0.0, 0.5, 0.5, 0.5);
	} else if (!any_piece_selected && piece_selectable) { //needs to be !any_piece_selected && piece_selectable
		COLOR=vec4(0.0, 0.0, 0.0, 0.0);
	} else if (any_piece_selected && selectable) {
		COLOR=vec4(0.9, 0.1, 0.0, 1.0);
	} else if (!any_piece_selected && exists_a_piece_to_move_here) {
		COLOR=vec4(0.0, 0.01, 0.04, .003);
	} else if ((length(center_position-selected_piece_position)<2.0) || exists_a_piece_to_move_here) {
		COLOR=vec4(0.0); //a "normal" blank spot, showing the color of the underlying hexagon.
	} else { //this is where the "Fog of War" is implemented, covering a spot (which can't be reached by "exists_a_piece_to_move_here") up with 3 meters of sealed space.
		
		COLOR=vec4(.01, .01, .01, 1.0);
	}
}

void fragment() {
	ALPHA=COLOR.a;
	if (ALPHA>.01) {
		ALBEDO=COLOR.rgb;
	}
	// Place fragment code here.
}
