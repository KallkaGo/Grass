#include '../includes/common.glsl'

varying vec4 vGrassData;
varying vec3 vColor;
varying vec3 vNormal;
varying vec3 vTerrianNormal;
varying vec3 vWorldPosition;
varying float tileX;
uniform vec4 grassParams;
uniform sampler2D tileDataTexture;
uniform float time;
uniform vec3 playerPos;
uniform vec3 moveDir;
uniform vec3 uBaseColor;
uniform vec3 uTipColor;

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
  return mat3(vec3(c, 0, -s), vec3(0, 1, 0), vec3(s, 0, c));
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
  return vec3(worldPos.x, noise(worldPos * .02) * 15.0, worldPos.z);
}

vec3 terrianNormal(vec3 worldPos) {
  float delta = .1;

  vec3 curPos = terrianHeight(worldPos);

  vec3 px = terrianHeight(worldPos + vec3(delta, 0., 0.));
  vec3 pz = terrianHeight(worldPos + vec3(0., 0., delta));

  vec3 tangent = px - curPos;

  vec3 bitangent = pz - curPos;

  vec3 normal = cross(bitangent, tangent);

  return normalize(normal);

}

float getGrassAttenuation(vec2 position,vec2 playerPosition,float dis)
{
    float distanceAttenuation = distance(playerPosition.xy, position) / dis;
    return 1.0 - clamp(0.0, 1.0, smoothstep(0.3, 1.0, distanceAttenuation));
}

const vec3 BASE_COLOR = vec3(0.14, 0.56, 0.06);
const vec3 TIP_COLOR = vec3(0.15, 0.65, 0.15);

void main() {

  int GRASS_SEGMENTS = int(grassParams.x);
  int GRASS_VERTICES = (GRASS_SEGMENTS + 1) * 2;

  float GRASS_PATCH_SIZE = grassParams.y;
  float GRASS_WIDTH = grassParams.z;
  float GRASS_HEIGHT = grassParams.w;

  // Figure out grass offset
  vec2 hashedInstanceID = hash21(float(gl_InstanceID)) * 2. - 1.;
  vec3 grassOffset = vec3(hashedInstanceID.x, 0, hashedInstanceID.y) * GRASS_PATCH_SIZE;

  vec3 originalGrassOffset = grassOffset;

  grassOffset = terrianHeight(grassOffset - vec3(playerPos.x, 0., playerPos.z));

  vec2 playerPosXZ = vec2(playerPos.x, playerPos.z);
  vec2 grassOffsetXZ = vec2(grassOffset.x, grassOffset.z);

  bool flag1 = abs(grassOffsetXZ.x - playerPosXZ.x) <= GRASS_PATCH_SIZE;
  bool flag2 = abs(grassOffsetXZ.y - playerPosXZ.y) <= GRASS_PATCH_SIZE;

  vec3 test = vec3(0.);

  if(!flag1) {
    // cuz grassOffset base to gl_InstanceID, so it won't change, dirX = sign(playerPosXZ.x - grassOffsetXZ.x) = sign(playerPosXZ.x)
    float dirX = sign(playerPosXZ.x - grassOffsetXZ.x);
    // Debug
    // test.x = dirX;
    // test.y = grassOffset.x;
    // test.z = 1.;
    grassOffset = terrianHeight(vec3(grassOffset.x + dirX * GRASS_PATCH_SIZE * 2.0, 0.0, grassOffset.z));
  }

  if(!flag2) {
    float dirZ = sign(playerPosXZ.y - grassOffsetXZ.y);
    grassOffset = terrianHeight(vec3(grassOffset.x, 0.0, grassOffset.z + dirZ * GRASS_PATCH_SIZE * 2.0));
  }

  vec4 grassBladeWorldPos = modelMatrix * vec4(grassOffset, 1.0);
  vec3 hashVal = hash(originalGrassOffset.xyz);

  // Grass rotation
  float angle = remap(hashVal.x, -1., 1., -PI, PI);

  // -x map 0 x map 1
  vec2 uv = vec2(originalGrassOffset.x, originalGrassOffset.z) / GRASS_PATCH_SIZE * .5 + .5;

  vec4 tileData = texture2D(tileDataTexture, uv);

  // Grass Type
  float grassType = saturate(hashVal.z) > .75 ? 1. : 0.;

  vec3 playPos = playerPos;

  float distanceAttenuation = getGrassAttenuation(vec2(grassBladeWorldPos.x, grassBladeWorldPos.z), vec2(playPos.x, playPos.z), 55.);

  float distanceTograss = distance(playPos, vec3(grassBladeWorldPos.x, 0., grassBladeWorldPos.z));

  float tiltFactor = clamp(distanceTograss / 3., 0.0, 1.0);
  // Debug
  // tiltFactor = 1.;

  // Stiffness
  float stiffness = 1.0;
  float tileGrassHeight = (1. - tileData.x) * mix(1., 1.5, grassType);
  tileGrassHeight = 1.;

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

  float width = GRASS_WIDTH * mix(1., smoothstep(0., .25, 1. - heightPercent), step(tileData.x, .7)) * tileGrassHeight * clamp(distanceAttenuation, .3, 1.);
  // float width = GRASS_WIDTH * easeOut(1. - heightPercent, 4.);
  // float width = GRASS_WIDTH * smoothstep(0., .25, 1. - heightPercent) * tileGrassHeight;
  // float width = GRASS_WIDTH;

  float height = GRASS_HEIGHT * tileGrassHeight * remap(hashVal.y, -1., 1., .7, 1.) * max(1., mix(1., 1.5, grassType) * tileData.x) * distanceAttenuation;

  float x = (xSide - .5) * width;
  float y = heightPercent * height;
  float z = 0.;

  // Grass lean factor
  float windStrength = noise(vec3(grassBladeWorldPos.xz * .05, 0.) + time * .5);

  float windAngle = PI / 4.;
  /* Debug */
  // windAngle = 0.;
  vec3 windAxis = vec3(sin(windAngle), 0., cos(windAngle));
  float windLeanAngle = windStrength * 1.5 * heightPercent * stiffness * clamp(tiltFactor, .05, 1.);
  float randomLeanAnmation = noise(vec3(originalGrassOffset.xz, time * 4.)) * (windStrength * .5 + .125) * clamp(tiltFactor, .2, 1.);

  /* Debug */
  // randomLeanAnmation = 0.;
  // windLeanAngle = 0.;

  float leanFactor = remap(hashVal.y, -1., 1., -0.5, 0.5) + randomLeanAnmation;

  /* Debug */
  // leanFactor = 0.;

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

  // curve is only applied in the yz plane
  vec3 grassLocalNormal = grassMat * vec3(0., curveRot90 * curveGrad.yz);

  // calculate terrian normal
  vec3 terrianNormal_ = terrianNormal(vec3(grassOffset.x, 0., grassOffset.z));

  vec3 grassFaceNormal = grassMat * vec3(0., 0., -zSide);

  vec3 impactDir = normalize(vec3(grassBladeWorldPos.x - playerPos.x, 0., grassBladeWorldPos.z - playerPos.z));

  const vec3 upVector = vec3(0., 1., 0.);

  vec3 impactAxis = normalize(cross(upVector, impactDir));

  grassMat = rotateAxis(impactAxis, (-PI * (1. - tiltFactor) / 4.)) * grassMat;

  vec3 grassLocalPisition = grassMat * vec3(x, y, z) + grassOffset;

  // Blend normal
  float distanceBlend = smoothstep(0., 10., distance(cameraPosition, grassBladeWorldPos.xyz));

  grassLocalNormal = mix(grassLocalNormal, vec3(0., 1., 0.), distanceBlend * 0.5);

  grassLocalNormal = normalize(grassLocalNormal);

  // ViewSpace ticken
  vec4 mvPosition = modelViewMatrix * vec4(grassLocalPisition, 1.0);

  vec3 viewDir = normalize(cameraPosition - grassBladeWorldPos.xyz);

  float NdotL = saturate(dot(grassFaceNormal, viewDir));

  float viewSpaceTickenFactor = easeOut(1. - NdotL, 4.) * smoothstep(0., .2, NdotL);

  mvPosition.x += viewSpaceTickenFactor * (xSide - .5) * width * .5 * -zSide;

  gl_Position = projectionMatrix * mvPosition;

  // Remove grass below threshold
  gl_Position.w = tileGrassHeight < .25 ? 0. : gl_Position.w;

  //Varying assignment area
  // vColor = mix(BASE_COLOR, TIP_COLOR, heightPercent);
  // vColor = mix(vec3(1., 0., 0.), vColor, stiffness);

  vec3 c1 = mix(uBaseColor, uTipColor, heightPercent);
  vec3 c2 = mix(vec3(0.6, 0.6, 0.4), vec3(0.88, 0.87, 0.52), heightPercent);

  float noiseValue = noise(grassBladeWorldPos.xyz * .1);

  vColor = mix(c1, c2, smoothstep(-1., 1., noiseValue));

  vGrassData = vec4(x, heightPercent, xSide, grassType);

  vNormal = normalize((modelMatrix * vec4(grassLocalNormal, 0.)).xyz);

  vTerrianNormal = terrianNormal_;

  vWorldPosition = (modelMatrix * vec4(grassLocalPisition, 1.0)).xyz;

  tileX = tileData.x;
}