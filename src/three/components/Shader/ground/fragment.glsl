varying vec3 vWorldPosition;
uniform sampler2D diffuseTexture;

float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}

float hash(vec2 p)  // replace this by something better
{
  p = 50.0 * fract(p * 0.3183099 + vec2(0.71, 0.113));
  return -1.0 + 2.0 * fract(p.x * p.y * (p.x + p.y));
}

void main() {

  // Grid
  float grid1 = texture(diffuseTexture, vWorldPosition.xz * 0.1).r;
  float grid2 = texture(diffuseTexture, vWorldPosition.xz * 1.0).r;

  float gridHash1 = hash(floor(vWorldPosition.xz * 1.0));

  vec3 gridColour = mix(vec3(0.5 + remap(gridHash1, -1.0, 1.0, -0.2, 0.2)), vec3(0.0625), grid2);
  gridColour = mix(gridColour, vec3(0.00625), grid1);

  vec3 colour = gridColour;

  // Debug
  // float d1 = length(vWorldPosition - vec3(0.0, 0.0, 5.0)) - 1.;
  // float d2 = length(vWorldPosition - vec3(5.0, 0.0, 0.0)) - 1.;
  // colour = mix(vec3(0., 0., 1.), vec3(0.), smoothstep(0.0, 0.1, d1));
  // colour = mix(vec3(1., 0., 0.), colour, smoothstep(0.0, 0.1, d2));

  gl_FragColor = vec4(pow(colour, vec3(1.0 / 2.2)), 1.0);
}