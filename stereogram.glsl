uniform sampler2D canvas;
uniform float separation, minSeparation;
uniform float xScale;

vec4 effect(vec4 color, sampler2D heightMap, vec2 uv, vec2 screen) {
	float height = Texel(heightMap, uv).r;
	uv.x = uv.x * xScale + mix(0, separation - minSeparation, height);
	return Texel(canvas, uv) * color;
}
