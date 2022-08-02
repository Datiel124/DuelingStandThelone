shader_type canvas_item;

uniform float thresh : hint_range(0, 1) = 1.0;
uniform sampler2D noise : hint_black;
uniform vec4 color : hint_color;

void fragment(){
	//Set its alpha if it is above threshhold.
	COLOR.a = 0.0;
	vec4 tex = texture(TEXTURE, UV);
	vec4 ntex = texture(noise, UV);
	if(tex.g > (thresh + ((ntex.r - 0.5) * 0.5))){
		COLOR.a = clamp(tex.a - (tex.r * thresh), 0, 1);
	}
}