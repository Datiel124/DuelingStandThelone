shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D tex : hint_black;

void vertex(){
	VERTEX += TANGENT * texture(tex, vec2(UV.x + TIME / 50.0, UV.y)).r * -50.0;
}

void fragment(){
	vec4 sampled = texture(tex, vec2(UV.x + TIME / 50.0, UV.y + TIME / 10.0));
	ALBEDO = vec3(0.0);
	if(sampled.r > 0.3 && sampled.r < 0.4){
		ALBEDO = vec3(0.0, 1.0, UV.x);
	}
}