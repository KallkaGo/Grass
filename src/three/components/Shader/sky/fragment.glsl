uniform vec2 resolution;

vec3 COLOUR_LIGHT_BLUE = vec3(0.42, 0.65, 0.85);
vec3 COLOUR_BRIGHT_BLUE = vec3(0.01, 0.2, 1.0);
vec3 COLOUR_LIGHT_RED = vec3(0.85, 0.28, 0.28);
vec3 COLOUR_DARK_YELLOW = vec3(0.25, 0.25, 0.0625);

void main() {
  vec2 uv = gl_FragCoord.xy / resolution.xy;

  float blueT = pow(smoothstep(0.0, 1.0, uv.y) * smoothstep(1.0, 0.0, uv.x), 0.5);
  float yellowT = 1.0 - pow(smoothstep(0.0, 1.0, uv.y) * smoothstep(1.0, 0.0, uv.x), 0.1);
  float blackT = 1.0 - pow(smoothstep(0.0, 0.5, uv.x) * smoothstep(1.0, 0.5, uv.y), 0.2);
  blackT *= smoothstep(0.0, 1.0, uv.y) * smoothstep(1.0, 0.0, uv.x);

  vec3 colour = mix(COLOUR_LIGHT_BLUE, COLOUR_BRIGHT_BLUE, blueT);
  colour = mix(colour, COLOUR_LIGHT_RED, yellowT * 0.75);
  colour = mix(colour, vec3(0.0), blackT * 0.75);

  gl_FragColor = vec4(pow(colour, vec3(1.0 / 2.2)), 1.0);
}