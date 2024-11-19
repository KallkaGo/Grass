#include '../includes/common.glsl'

varying vec2 vUvs;
varying vec3 vNormal;
varying vec3 vWorldPosition;
varying vec3 vColor;
varying vec4 vGrassData;
uniform vec2 resolution;

vec3 hemiLight(vec3 normal, vec3 groundColor, vec3 skyColor) {
  return mix(groundColor, skyColor, .5 * normal.y + .5);
}

vec3 lambertLight(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor) {
  float wrap = .5;
  float NdotL = saturate((dot(normal, lightDir) + wrap) / 1. + wrap);
  vec3 lighting = vec3(NdotL);

  float backlight = saturate((dot(viewDir, -lightDir) + wrap) / 1. + wrap);

  vec3 scatter = vec3(pow(backlight, 2.0));

  lighting += scatter;

  return lighting * lightColor;
}

void main() {
  float grassX = vGrassData.x;

  vec3 normal = normalize(vNormal);

  vec3 viewDir = normalize(cameraPosition - vWorldPosition);

  vec3 baseColor = mix(vColor * .75, vColor, smoothstep(.125, 0., abs(grassX)));

  // hemi
  vec3 color1 = vec3(1., 1., .75);
  vec3 color2 = vec3(.05, .05, .25);

  vec3 ambientLight = hemiLight(normal, color2, color1);

  vec3 lightDir = normalize(vec3(-1., .5, 1.));
  vec3 lightColor = vec3(1.);
  vec3 diffuseLighting = lambertLight(normal, viewDir, lightDir, lightColor);
  vec3 lighting = diffuseLighting * .5 + ambientLight * .5;

  vec3 color = baseColor * lighting;

  // color = ambientLight;

  gl_FragColor = vec4(pow(color, vec3(1.0 / 2.2)), 1.0);
}
