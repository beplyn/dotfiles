// The screen in two tones of the Stylix palette: dark parts in the
// background colour, light parts in the foreground, a calm reading mode.
// plugins.nix fills in the colours; hyprshade applies it (Mod+Alt+S).
#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const vec3 background = @background@;
const vec3 foreground = @foreground@;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    float luma = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    fragColor = vec4(mix(background, foreground, luma), pixColor.a);
}
