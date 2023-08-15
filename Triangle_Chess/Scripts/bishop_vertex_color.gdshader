shader_type spatial;
instance uniform bool black; //the piece is assumed white unless the uniform here is changed by the bishop script.
render_mode cull_back, depth_draw_always;
void vertex() {
	if (black) {
		COLOR.r=1.0-COLOR.r;
		COLOR.g=1.0-COLOR.g;
		COLOR.b=1.0-COLOR.b;
		
	}
	COLOR.a=1.0;
}

void fragment() {
	// Place fragment code here.
	ALBEDO=COLOR.rgb;
	ALPHA=COLOR.a;
}
