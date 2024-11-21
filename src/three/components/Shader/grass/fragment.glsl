#include '../includes/common.glsl'

varying vec2 vUvs;
varying float tileX;
varying vec3 vNormal;
varying vec3 vTerrianNormal;
varying vec3 vWorldPosition;
varying vec3 vColor;
varying vec4 vGrassData;
uniform vec2 resolution;
uniform sampler2DArray grassDiffuseTex;

vec3 hemiLight(vec3 normal, vec3 groundColor, vec3 skyColor) {
  return mix(groundColor, skyColor, .5 * normal.y + .5);
}

vec3 lambertLight(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor) {
  float wrap = .5;
  float NdotL = saturate(dot(normal, lightDir) + wrap / (1. + wrap));
  vec3 lighting = vec3(NdotL);

  float backlight = saturate(dot(viewDir, -lightDir) + wrap / (1. + wrap));

  vec3 scatter = vec3(pow(backlight, 2.0));

  lighting += scatter;

  return lighting * lightColor;
}

vec3 phongSpecular(vec3 normal, vec3 lgihtDir, vec3 viewDir) {
  float NdotL = saturate(dot(normal, lgihtDir));

  vec3 r = normalize(reflect(-lgihtDir, normal));

  float phongValue = max(0., dot(viewDir, r));
  phongValue = pow(phongValue, 32.);

  vec3 specular = NdotL * vec3(phongValue);

  return specular;
}

vec4 grassDiffuse(vec2 uv, float grassType) {

  vec4 diffuse = texture2D(grassDiffuseTex, vec3(uv, grassType));

  vec4 mixColor = min(vec4(1.), vec4(vColor, 1.) * 1.2);

  mixColor = mix(diffuse, mixColor, 1. - tileX);

  if(mixColor.a < .7)
    discard;

  return mixColor;
}

void main() {
  float grassX = vGrassData.x;

  float grassY = vGrassData.y;

  float grassType = vGrassData.w;

  vec2 uv = vGrassData.zy;

  vec3 normal = normalize(vNormal);

  vec3 terrianNormal = normalize(vTerrianNormal);

  vec3 viewDir = normalize(cameraPosition - vWorldPosition);

  // diffuse

  vec4 baseColor = grassDiffuse(uv, grassType);

  // vec3 baseColor = mix(vColor * .75, vColor, smoothstep(.125, 0., abs(grassX)));

  // hemi
  vec3 color1 = vec3(1., 1., .75);
  vec3 color2 = vec3(0.45, 0.65, 0.14);
  vec3 ambientLight = hemiLight(normal, color2, color1);

  // Directional Light
  vec3 lightDir = normalize(vec3(-1., .5, 1.));
  vec3 lightColor = vec3(1.);
  vec3 diffuseLighting = lambertLight(terrianNormal, viewDir, lightDir, lightColor);

  // Specular
  vec3 specular = phongSpecular(terrianNormal, lightDir, viewDir);

  // AO
  float ao = remap(pow(grassY, 2.), 0., 1., .6, 1.);

  vec3 lighting = diffuseLighting * .2 + ambientLight * .8;

  vec3 albedo = baseColor.rgb * lighting + specular * .25;

  // albedo = specular;

  albedo *= ao;

  // gamma correct
  gl_FragColor = vec4(pow(albedo, vec3(1.0 / 2.2)), 1.0);
}
