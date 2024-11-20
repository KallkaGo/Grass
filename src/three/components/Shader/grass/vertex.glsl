#include '../includes/common.glsl'

varying vec4 vGrassData;
varying vec3 vColor;
varying vec3 vNormal;
varying vec3 vWorldPosition;
uniform vec4 grassParams;
uniform sampler2D tileDataTexture;
uniform float time;

#define PI 3.14159

uvec2 murmurHash21(uint src) {
  const uint M = 0x5bd1e995u;
  uvec2 h = uvec2(1190494759u, 2147483647u);
  src *= M;
  src ^= src >> 24u;
  src *= M;
  h *= M;
  h ^= src;
  h ^= h >> 13u;
  h *= M;
  h ^= h >> 15u;
  return h;
}

vec2 hash21(float src) {
  uvec2 h = murmurHash21(floatBitsToUint(src));
  return uintBitsToFloat(h & 0x007fffffu | 0x3f800000u) - 1.0;
}

float easeOut(float x, float t) {
  return 1. - pow(1. - x, t);
}

mat3 rotateY(float theta) {
  float c = cos(theta);
  float s = sin(theta);
  return mat3(vec3(c, 0, s), vec3(0, 1, 0), vec3(-s, 0, c));
}

mat3 rotateAxis(vec3 axis, float angle) {
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c);
}

vec3 bezier(vec3 P0, vec3 P1, vec3 P2, vec3 P3, float t) {
  return (1.0 - t) * (1.0 - t) * (1.0 - t) * P0 +
    3.0 * (1.0 - t) * (1.0 - t) * t * P1 +
    3.0 * (1.0 - t) * t * t * P2 +
    t * t * t * P3;
}

vec3 bezierGrad(vec3 P0, vec3 P1, vec3 P2, vec3 P3, float t) {
  return 3.0 * (1.0 - t) * (1.0 - t) * (P1 - P0) +
    6.0 * (1.0 - t) * t * (P2 - P1) +
    3.0 * t * t * (P3 - P2);
}

vec3 terrianHeight(vec3 worldPos) {
  return vec3(worldPos.x, noise(worldPos * .02) * 10.0, worldPos.z);
}

const vec3 BASE_COLOR = vec3(0.1, 0.4, 0.04);
const vec3 TIP_COLOR = vec3(0.5, 0.7, 0.3);

void main() {

  int GRASS_SEGMENTS = int(grassParams.x);
  int GRASS_VERTICES = (GRASS_SEGMENTS + 1) * 2;

  float GRASS_PATCH_SIZE = grassParams.y;
  float GRASS_WIDTH = grassParams.z;
  float GRASS_HEIGHT = grassParams.w;

  // Figure out grass offset
  vec2 hashedInstanceID = hash21(float(gl_InstanceID)) * 2. - 1.;
  vec3 grassOffset = vec3(hashedInstanceID.x, 0, hashedInstanceID.y) * GRASS_PATCH_SIZE;

  grassOffset = terrianHeight(grassOffset);

  vec4 grassBladeWorldPos = modelMatrix * vec4(grassOffset, 1.0);
  vec3 hashVal = hash(grassBladeWorldPos.xyz);

  // Grass rotation
  float angle = remap(hashVal.x, -1., 1., -PI, PI);
  // -x map 0 x map 1
  vec4 tileData = texture2D(tileDataTexture, vec2(grassBladeWorldPos.x, grassBladeWorldPos.z) / GRASS_PATCH_SIZE * .5 + .5);

  // Grass Type
  float grassType = saturate(hashVal.z) > .75 ? 1. : 0.;

  // Stiffness
  float stiffness = 1.0;
  float tileGrassHeight = (1. - tileData.x) * mix(1., 1.5, grassType);

  // debug
  // grassOffset = vec3(float(gl_InstanceID) * .5 - 8., 0., 0.);
  // angle = float(gl_InstanceID) * .2;

  // Figure out vertex id
  int vertexFB_ID = gl_VertexID % (GRASS_VERTICES * 2);
  int vertex_ID = vertexFB_ID % GRASS_VERTICES;

  // 0 = left, 1 = right 奇偶性
  int xTest = vertex_ID & 0x1;
  // > GRASS_VERTICES is other side frontSide or BackSide
  int zTest = (vertexFB_ID >= GRASS_VERTICES) ? 1 : -1;

  float xSide = float(xTest);
  float zSide = float(zTest);

  float heightPercent = float(vertex_ID - xTest) / (float(GRASS_SEGMENTS) * 2.);

  // float width = GRASS_WIDTH * easeOut(1. - heightPercent, 4.);

  // float width = GRASS_WIDTH * smoothstep(0., .25, 1. - heightPercent) * tileGrassHeight;

  float width = GRASS_WIDTH;

  float height = GRASS_HEIGHT * tileGrassHeight;

  float x = (xSide - .5) * width;
  float y = heightPercent * height;
  float z = 0.;

  // float offset = float(gl_InstanceID) * .5;

  // Grass lean factor

  float windStrength = noise(vec3(grassBladeWorldPos.xz * .05, 0.) + time * .5);
  float windAngle = PI / 4.;
  vec3 windAxis = vec3(cos(windAngle), 0., sin(windAngle));
  float windLeanAngle = windStrength * 1.5 * heightPercent * stiffness;
  // float randomLeanAnmation = sin(time * 2. + hashVal.y) * .025;
  float randomLeanAnmation = noise(vec3(grassBladeWorldPos.xz, time * 4.)) * (windStrength * .5 + .125);

  // debug
  // randomLeanAnmation = 0.;
  // windLeanAngle = 0.;

  float leanFactor = remap(hashVal.y, -1., 1., -0.5, 0.5) + randomLeanAnmation;

  // Debug
  // leanFactor = 1.;

  // Add the bezier curve for bend
  vec3 p1 = vec3(0.);
  vec3 p2 = vec3(0., .33, 0.);
  vec3 p3 = vec3(0., .66, 0.);
  vec3 p4 = vec3(0., cos(leanFactor), sin(leanFactor));

  vec3 curve = bezier(p1, p2, p3, p4, heightPercent);

  // Calculate normal
  // bezierGrad return tangent at curve
  vec3 curveGrad = bezierGrad(p1, p2, p3, p4, heightPercent);

  // column major
  mat2 curveRot90 = mat2(0., 1., -1., 0.) * -zSide;

  y = curve.y * height;

  z = curve.z * height;

  // Generate grass matrix
  mat3 grassMat = rotateAxis(windAxis, windLeanAngle) * rotateY(angle);

  vec3 grassLocalPisition = grassMat * vec3(x, y, z) + grassOffset;

  // curve is only applied in the yz plane
  vec3 grassLocalNormal = grassMat * vec3(0., curveRot90 * curveGrad.yz);

  // Blend normal
  float distanceBlend = smoothstep(0., 10., distance(cameraPosition, grassBladeWorldPos.xyz));

  grassLocalNormal = mix(grassLocalNormal, vec3(0., 1., 0.), distanceBlend * 0.5);

  grassLocalNormal = normalize(grassLocalNormal);

  // ViewSpace ticken
  vec4 mvPosition = modelViewMatrix * vec4(grassLocalPisition, 1.0);

  vec3 viewDir = normalize(cameraPosition - grassBladeWorldPos.xyz);
  vec3 grassFaceNormal = grassMat * vec3(0., 0., -zSide);

  float NdotL = saturate(dot(grassFaceNormal, viewDir));

  float viewSpaceTickenFactor = easeOut(1. - NdotL, 4.) * smoothstep(0., .2, NdotL);

  mvPosition.x += viewSpaceTickenFactor * (xSide - .5) * width * .5 * -zSide;

  gl_Position = projectionMatrix * mvPosition;

  // Remove grass below threshold
  gl_Position.w = tileGrassHeight < .25 ? 0. : gl_Position.w;

  // gl_Position = projectionMatrix * modelViewMatrix * vec4(grassLocalPisition, 1.0);

  vColor = mix(BASE_COLOR, TIP_COLOR, heightPercent);
  vColor = mix(vec3(1., 0., 0.), vColor, stiffness);

  // vColor = vec3(viewSpaceTickenFactor);

  // vColor = grassLocalNormal;

  // vec3 c1 = mix(BASE_COLOR, TIP_COLOR, heightPercent);
  // vec3 c2 = mix(vec3(0.6, 0.6, 0.4), vec3(0.88, 0.87, 0.52), heightPercent);

  // float noiseValue = noise(grassBladeWorldPos.xyz * .1);

  // vColor = mix(c1, c2, smoothstep(-1., 1., noiseValue));

  vGrassData = vec4(x, heightPercent, xSide, grassType);

  vNormal = normalize((modelMatrix * vec4(grassLocalNormal, 0.)).xyz);

  vWorldPosition = (modelMatrix * vec4(grassLocalPisition, 1.0)).xyz;
}