#include '../includes/common.glsl'

varying vec3 vWorldPosition;
varying vec3 vWorldNormal;
varying vec2 vUv;

vec3 terrianHeight(vec3 worldPos) {
  return vec3(worldPos.x, noise(worldPos * .02) * 15.0, worldPos.z);
}

void main() {
  vec4 localSpacePosition = vec4(position, 1.0);
  vec4 worldPosition = modelMatrix * localSpacePosition;

  worldPosition.xyz = terrianHeight(worldPosition.xyz);

  vWorldPosition = worldPosition.xyz;
  vWorldNormal = normalize((modelMatrix * vec4(normal, 0.0)).xyz);
  vUv = uv;

  gl_Position = projectionMatrix * viewMatrix * worldPosition;
}