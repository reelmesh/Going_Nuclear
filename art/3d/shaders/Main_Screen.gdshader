// This is the final, clean shader for your 3D screens.
shader_type spatial;

// --- Uniforms ---
// We only declare the variables we are actually using.
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);

// This is the texture for our text overlay.
uniform sampler2D text_overlay_texture;

// These are the built-in controls for UV mapping that we will use in the vertex function.
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;


void vertex() {
	// --- The Definitive UV Remapping and Scaling ---
	// 1. Remap the model's flat coordinates from [-0.5, 0.5] to the [0, 1] texture space.
	vec2 remapped_uv = VERTEX.xz;

	// 2. Apply the scale and offset from the Inspector to the remapped coordinates.
	// We use .xy because UV is a 2D coordinate.
	UV = remapped_uv * uv1_scale.xz + uv1_offset.xz;
}


void fragment() {
	// --- Base Screen Color & Emission ---
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	vec3 emission_tex = texture(texture_emission, base_uv).rgb;
	vec3 base_emission = (emission.rgb + emission_tex) * emission_energy;

	// --- Text Overlay Blending ---
	vec4 text_color = texture(text_overlay_texture, base_uv);

	// Blend the final emission color with black, using the text's alpha as a mask.
	vec3 final_emission = mix(base_emission, vec3(0.0, 0.0, 0.0), text_color.a);

	EMISSION = final_emission;
}