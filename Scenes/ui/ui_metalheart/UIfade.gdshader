shader_type canvas_item;

uniform float fillIn : hint_range(0, 2) = 0.8;
uniform float fillOut : hint_range(0, 1) = 0.5;

uniform vec4 rimColor : hint_color = vec4(1.0);
uniform float rimSize = 100;
uniform float rimFade = 200;

void fragment(){
	COLOR = texture(TEXTURE, UV);
	if(UV.r > fillIn)
		COLOR.a = 0.0;
	
	//the edge thats fading in should glow brightly
	//fade the edge by using the pixel's position to the fillIn position
	float edge = fillIn - UV.r;
	//The "edge" is the distance of the pixel to the rim.
	//Everything below rimSize * TEXTURE_PIXEL_SIZE.r should be colored in completely.
	if(edge < rimSize)
		COLOR.rgb = rimColor.rgb;
	//Everything else should be faded by the rimFade.
	else
		//the fade STARTS  where edge is > rimSize * TEXTURE_PIXEL_SIZE.r, and should END fade distance away
		COLOR.rgb = mix(COLOR.rgb, rimColor.rgb, clamp(1.0 - (edge - rimSize) / (rimFade), 0, 1));
	
	if(UV.r < fillOut)
		COLOR.a = 0.0;
}