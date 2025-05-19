shader_type canvas_item;

uniform vec4 silhouette_color : source_color = vec4(0.027, 0.004, 0.110, 1.0); // #07011C

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Keep alpha, replace RGB with silhouette color
    COLOR = vec4(silhouette_color.rgb, tex_color.a);
}
