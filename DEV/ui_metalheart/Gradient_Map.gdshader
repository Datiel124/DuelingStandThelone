shader_type canvas_item;

uniform sampler2D gradient : hint_black;

void fragment() {
    vec4 input = textureLod(SCREEN_TEXTURE, SCREEN_UV, 2.0);
	float grey = dot(input.rgb, vec3(0.299, 0.587, 0.114));
	vec3 sampled_color = texture(gradient, vec2(grey, 0.0)).rgb;
	COLOR.rgb = sampled_color;
}	