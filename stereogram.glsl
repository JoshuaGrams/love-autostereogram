uniform sampler2D canvas;
uniform float maxOffsetUV;
uniform float fadeUV;
uniform float xScale;

vec4 effect(vec4 color, sampler2D heightMap, vec2 uv, vec2 screen) {
	float height = Texel(heightMap, uv).r * min(1, uv.x/fadeUV);
	uv.x = uv.x * xScale + mix(0, maxOffsetUV, height);
	return Texel(canvas, uv) * color;
}
