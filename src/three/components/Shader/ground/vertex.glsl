#include '../includes/common.glsl'

varying vec3 vWorldPosition;
varying vec3 vWorldNormal;
varying vec2 vUv;

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

void main() {
  vec4 localSpacePosition = vec4(position, 1.0);
  vec4 worldPosition = modelMatrix * localSpacePosition;

  worldPosition.xyz = terrianHeight(worldPosition.xyz);

  vWorldPosition = worldPosition.xyz;
  vWorldNormal = terrianNormal(worldPosition.xyz);
  vUv = uv;

  gl_Position = projectionMatrix * viewMatrix * worldPosition;
}