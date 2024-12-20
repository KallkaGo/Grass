#include '../includes/common.glsl'

varying vec2 vUv;
varying vec3 vWorldPosition;
varying vec3 vWorldNormal;
uniform sampler2D diffuseTexture;
uniform sampler2D groundTex;
uniform sampler2D roughnessTex;
uniform vec3 groundColor;

float hash(vec2 p)  // replace this by something better
{
  p = 50.0 * fract(p * 0.3183099 + vec2(0.71, 0.113));
  return -1.0 + 2.0 * fract(p.x * p.y * (p.x + p.y));
}

vec3 hemiLight(vec3 normal, vec3 groundColor, vec3 skyColor) {
  return mix(groundColor, skyColor, .5 * normal.y + .5);
}

vec3 lambertLight(vec3 normal, vec3 lightDir, vec3 lightColor) {
  float wrap = .5;
  float NdotL = saturate(dot(normal, lightDir) + wrap / (1. + wrap));
  vec3 lighting = vec3(NdotL);

  return lighting * lightColor;
}

void main() {

  vec3 colour = vec3(0.);

  // Grid
  float grid1 = texture(diffuseTexture, vWorldPosition.xz * 0.1).r;
  float grid2 = texture(diffuseTexture, vWorldPosition.xz * 1.0).r;

  float gridHash1 = hash(floor(vWorldPosition.xz * 1.0));

  vec3 gridColour = mix(vec3(0.5 + remap(gridHash1, -1.0, 1.0, -0.2, 0.2)), vec3(0.0625), grid2);
  gridColour = mix(gridColour, vec3(0.00625), grid1);

  colour = gridColour;

  // Ground

  vec4 groundTex = texture2D(groundTex, vUv);
  colour = groundTex.rgb;
  colour = groundColor;

  // Roughness
  vec3 roughnessTex = texture(roughnessTex, vUv).rgb;

  colour *= roughnessTex;

  // Lighting
  vec3 lightDir = normalize(vec3(-1., .5, 1.));
  vec3 terrianNormal = normalize(vWorldNormal);

  vec3 color1 = vec3(1., 1., .75);
  vec3 color2 = vec3(0.45, 0.65, 0.14);
  vec3 ambientLight = hemiLight(terrianNormal, color2, color1);
  vec3 diffuseLighting = lambertLight(terrianNormal, lightDir, vec3(1.));

  vec3 lighting = ambientLight * 0.5 + diffuseLighting * 0.5;

  vec3 aledo = colour * lighting;

  // Debug
  // float d1 = length(vWorldPosition - vec3(0.0, 0.0, 5.0)) - 1.;
  // float d2 = length(vWorldPosition - vec3(5.0, 0.0, 0.0)) - 1.;
  // colour = mix(vec3(0., 0., 1.), vec3(0.), smoothstep(0.0, 0.1, d1));
  // colour = mix(vec3(1., 0., 0.), colour, smoothstep(0.0, 0.1, d2));

  gl_FragColor = vec4(pow(aledo, vec3(1.0 / 2.2)), 1.0);
}