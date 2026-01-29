shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float blur_amount : hint_range(0.0, 10.0) = 2.0;
uniform int blur_quality : hint_range(1, 4) = 3;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 tex_size = 1.0 / vec2(textureSize(screen_tex, 0));
    vec4 col = vec4(0.0);
    float total_weight = 0.0;

    int half_kernel = blur_quality;
    float sigma = blur_amount * 0.4;
    float sigma_sq = sigma * sigma;

    for (int x = -half_kernel; x <= half_kernel; x++) {
        for (int y = -half_kernel; y <= half_kernel; y++) {
            vec2 offset = vec2(float(x), float(y)) * tex_size * blur_amount;

            float distance_sq = float(x * x + y * y);
            float weight = exp(-distance_sq / (2.0 * sigma_sq));

            col += texture(screen_tex, SCREEN_UV + offset) * weight;
            total_weight += weight;
        }
    }

    col = col / total_weight;

    float noise = fract(sin(dot(SCREEN_UV, vec2(12.9898, 78.233))) * 43758.5453);
    col.rgb += (noise - 0.5) * dither_strength / 255.0;

    COLOR = col;
}
