shader_type spatial;
render_mode unshaded, cull_back, depth_draw_always;

uniform sampler2D noisiness;
uniform float xscroll = 1.0;
uniform float yscroll = 1.0;

uniform vec4 edgecolor : hint_color;



float map(float value, float low1, float high1, float low2, float high2){
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void fragment(){
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	vec4 noise = texture(noisiness, vec2(UV.x - (TIME*xscroll), UV.y + (TIME*yscroll)));
	
	vec2 d = texture(noisiness, vec2(UV.x - (TIME*xscroll), UV.y + (TIME*yscroll))).xy - vec2(0.5);
	ALBEDO.rgb = texture(SCREEN_TEXTURE, SCREEN_UV + d * 1.0 / (linear_depth / (1.0 - dot(normalize(NORMAL), normalize(VIEW))))).rgb;
	ALBEDO.rgb += mix(vec4(0.0), edgecolor, pow(1.0 - dot(normalize(NORMAL), normalize(VIEW)),5)).rgb;
	}