shader_type canvas_item;

uniform float time;
uniform float pixelation = 1.0; // number of horizontal virtual pixels

void fragment() {
    // Pixelation
    vec2 pixel_uv = floor(UV * pixelation) / pixelation;

    // Save for circular mask before UV warping
    vec2 circle_uv = pixel_uv;

    // Centered and normalized to [-1, 1]
    vec2 uv = pixel_uv * 2.0 - 1.0;

    // Rotate
    float angle = time * 1.0;
    mat2 rot = mat2(
        vec2(cos(angle), -sin(angle)),
        vec2(sin(angle),  cos(angle))
    );
    uv = rot * uv;

    // Kaleidoscope effect
    float slices = 2.0;
    float mirrored_angle = atan(uv.y, uv.x);
    mirrored_angle = mod(mirrored_angle, 6.28318 / slices);
    vec2 kaleido_uv = vec2(cos(mirrored_angle), sin(mirrored_angle));

    float red_wave  = 0.5 + 0.5 * sin(kaleido_uv.x * 10.0 + time * 3.0);
    float blue_wave = 0.5 + 0.5 * sin(kaleido_uv.y * 10.0 + time * 3.5);

    float r_col = clamp(red_wave * 0.8 + 0.2, 0.0, 1.0);
    float g_col = 0.0;
    float b_col = clamp(blue_wave * 0.8 + 0.2, 0.0, 1.0);

    // Circular mask
    vec2 centered = circle_uv - vec2(0.5);
    float dist = length(centered);
    if (dist > 0.5) {
        discard;
    }

    COLOR.rgb = vec3(r_col, g_col, b_col);
    COLOR.a = 1.0;
}
