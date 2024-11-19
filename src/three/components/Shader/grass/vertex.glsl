varying vec4 vGrassData;
varying vec3 vColor;
varying vec3 vNormal;
varying vec3 vWorldPosition;
uniform vec4 grassParams;
uniform float time;

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

// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
//
// https://www.shadertoy.com/view/Xsl3Dl
vec3 hash(vec3 p) // replace this by something better
{
  p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));

  return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
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

float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}

float saturate(float x) {
  return clamp(x, 0.0, 1.0);
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

float noise(in vec3 p) {
  vec3 i = floor(p);
  vec3 f = fract(p);

  vec3 u = f * f * (3.0 - 2.0 * f);

  return mix(mix(mix(dot(hash(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0)), dot(hash(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0)), u.x), mix(dot(hash(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0)), dot(hash(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0)), u.x), u.y), mix(mix(dot(hash(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0)), dot(hash(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0)), u.x), mix(dot(hash(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0)), dot(hash(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
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

  vec4 grassBladeWorldPos = modelMatrix * vec4(grassOffset, 1.0);
  vec3 hashVal = hash(grassBladeWorldPos.xyz);

  const float PI = 3.14159;
  float angle = remap(hashVal.x, -1., 1., -PI, PI);

  // debug
  // grassOffset = vec3(float(gl_InstanceID) * .5 - 8., 0., 0.);
  // angle = float(gl_InstanceID) * .2;

  // Figure out vertex id, > GRASS_VERTICES is other side
  int vertexFB_ID = gl_VertexID % (GRASS_VERTICES * 2);
  int vertex_ID = vertexFB_ID % GRASS_VERTICES;

  // 0 = left, 1 = right 奇偶性
  int xTest = vertex_ID & 0x1;
  int zTest = (vertexFB_ID >= GRASS_VERTICES) ? 1 : -1;

  float xSide = float(xTest);
  float zSide = float(zTest);

  float heightPercent = float(vertex_ID - xTest) / (float(GRASS_SEGMENTS) * 2.);

  // float width = GRASS_WIDTH * easeOut(1. - heightPercent, 4.);

  float width = GRASS_WIDTH * smoothstep(0., .25, 1. - heightPercent);

  float height = GRASS_HEIGHT;

  float x = (xSide - .5) * width;
  float y = heightPercent * height;
  float z = 0.;

  // float offset = float(gl_InstanceID) * .5;

  // Grass lean factor

  float windStrength = noise(vec3(grassBladeWorldPos.xz * .05, 0.) + time);
  float windAngle = 3.14159 / 4.;
  vec3 windAxis = vec3(cos(windAngle), 0., sin(windAngle));

  float windLeanAngle = windStrength * 1.5 * heightPercent;

  // float randomLeanAnmation = sin(time * 2. + hashVal.y) * .025;
  float randomLeanAnmation = noise(vec3(grassBladeWorldPos.xz, time * 4.)) * (windStrength * .5 + .125);
  randomLeanAnmation = 0.;
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

  grassLocalNormal = mix(grassLocalNormal, vec3(0., 1., 0.), distanceBlend * .5);

  grassLocalNormal = normalize(grassLocalNormal);

  gl_Position = projectionMatrix * modelViewMatrix * vec4(grassLocalPisition, 1.0);

  vColor = mix(BASE_COLOR, TIP_COLOR, heightPercent);

  // vec3 c1 = mix(BASE_COLOR, TIP_COLOR, heightPercent);
  // vec3 c2 = mix(vec3(0.6, 0.6, 0.4), vec3(0.88, 0.87, 0.52), heightPercent);

  // float noiseValue = noise(grassBladeWorldPos.xyz * .1);

  // vColor = mix(c1, c2, smoothstep(-1., 1., noiseValue));

  // vColor = grassLocalNormal;

  vGrassData = vec4(x, 0., 0., 0.);

  vNormal = normalize((modelMatrix * vec4(grassLocalNormal, 0.)).xyz);

  vWorldPosition = (modelMatrix * vec4(grassLocalPisition, 1.0)).xyz;
}