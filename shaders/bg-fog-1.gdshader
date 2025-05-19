shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fog_strength : hint_range(0.0, 1.0) = 0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    // Simulate fog by blending with fog_color
    COLOR = mix(tex_color, fog_color, fog_strength * tex_color.a);
}
