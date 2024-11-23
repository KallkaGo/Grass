#include '../includes/common.glsl'

uniform vec3 uBallPos;
uniform float halfHeight;

vec3 terrianHeight(vec3 worldPos) {
  return vec3(worldPos.x, noise(worldPos * .02) * 15.0, worldPos.z);
}

void main() {
  vec3 worldPos = (modelMatrix * vec4(position, 1.0)).xyz;
  vec3 Offset = terrianHeight(uBallPos);
  worldPos += Offset;
  worldPos.y += halfHeight;
  csm_PositionRaw = projectionMatrix * viewMatrix * vec4(worldPos, 1.0);
}